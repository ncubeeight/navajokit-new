//
//  NVTranslator+Transformer.swift
//  NavajoKitTransformer
//
//  Sentence translation with the encoder/decoder transformer models,
//  split out of NavajoKit so apps that only need word lookups, tagging
//  and pronunciation don't ship the models (~33 MB). Add the
//  NavajoKitTransformer product and `import NavajoKitTransformer` to use
//  `translate(_:tokenizer:)` exactly as before.
//
//  Translation code by Daniel Gump.
//

import CoreML
import Foundation
import NavajoKit

/// The encoder and decoder, loaded once on first use rather than when an
/// NVTranslator is created.
final class NVTransformerModels: @unchecked Sendable {

	static let shared = NVTransformerModels()

	let encoder: NavajoEncoder
	let decoder: NavajoDecoder
	let maxLen = 128

	private init() {
		let config = MLModelConfiguration()
		config.computeUnits = .all //.cpuAndNeuralEngine

		encoder = try! NavajoEncoder(configuration: config)
		decoder = try! NavajoDecoder(configuration: config)
	}
}

public extension NVTranslator {

	/**
		Translate a Navajo sentence to English with the transformer models

		- Parameters:
			- text: The Navajo text
			- tokenizer: Tokenizer whose vocabulary matches the models
		- Returns: The English translation
	 */
	func translate(_ text: String, tokenizer: NVTokenizer) -> String {

		let models = NVTransformerModels.shared
		let maxLen = models.maxLen

		let tokens = tokenizer.encode(text)

		let src = try! MLMultiArray(
			shape: [1, NSNumber(value: maxLen)],
			dataType: .int32
		)

		for i in 0..<maxLen {
			let val = i < tokens.count ? Int32(tokens[i]) : Int32(0)  // PAD=0
			src[i] = NSNumber(value: val)
		}

		let encInput = NavajoEncoderInput(source: src)
		let encOutput = try! models.encoder.prediction(input: encInput)
		let memory = encOutput.memory

		var decoded: [Int] = [NVTokenizer.BOS]

		for _ in 0..<(maxLen - 1) {

			let dest = try! MLMultiArray(
				shape: [1, NSNumber(value: maxLen)],
				dataType: .int32
			)

			for i in 0..<maxLen {
				let val = i < decoded.count ? Int32(decoded[i]) : Int32(0)
				dest[i] = NSNumber(value: val)
			}

			let decInput = NavajoDecoderInput(target: dest, memory: memory)
			let decOutput = try! models.decoder.prediction(input: decInput)

			let logits = decOutput.logits
			let timestep = decoded.count - 1

			let nextToken = Self.argmax(logits: logits, timestep: timestep)

			if nextToken == NVTokenizer.EOS { break }

			decoded.append(nextToken)
		}

		let filtered = decoded.dropFirst().prefix(while: { $0 != NVTokenizer.EOS })
		return tokenizer.decode(tokens: Array(filtered))
	}

	private static func argmax(logits: MLMultiArray, timestep: Int) -> Int {

		let vocabSize = logits.shape[2].intValue

		var bestToken = 0
		var bestScore = -Float.infinity

		for v in 0..<vocabSize {

			let score = logits.value([0, timestep, v])

			if score > bestScore {

				bestScore = score
				bestToken = v
			}
		}

		return bestToken
	}
}
