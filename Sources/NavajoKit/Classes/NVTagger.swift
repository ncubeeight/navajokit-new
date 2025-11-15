//
//  NVTagger.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/14/25.
//

import CoreML
import NaturalLanguage

///Tag tokenized text using the built-in parts-of-speech tagger model
public actor NVTagger {

	///Singleton
	public static let shared = NVTagger()

	private var debug = false
	private var nvModel: NLModel?

	/**
		Initializer

		- Parameters:
			- debug: activate console logging
	 */
	public init(debug: Bool = false) {

		self.debug = debug

		nvModel = Self.loadModel()
	}

	/**
		Apply part-of-speech tags to an array of tokenized text

		- Parameters:
			- Array of pre-tokenized `String` text
		- Returns: Array of `NVTaggedWord` objects constructed from the model's most-probable predictions
	 */
	public func tag(_ tokenText: [String]) -> [NVTaggedWord] {

		let labels = nvModel?.predictedLabels(forTokens: tokenText.map({ return $0.lowercased() })) ?? []

		var tags: [NVTaggedWord] = []
		for (index, label) in labels.enumerated() {

			let fixedLabel = label.isEmpty ? "Sp" : label

			let tag = NVTaggedWord(token: tokenText[index], label: fixedLabel, translation: nil)
			tags.append(tag)
		}

		return tags
	}

	private nonisolated static func loadModel() -> NLModel {

		let model = try! MLModel.loadModel(named: "NavajoTagger", configuration: MLModelConfiguration())

		let nlModel = try! NLModel(mlModel: model)

		return nlModel
	}


}
