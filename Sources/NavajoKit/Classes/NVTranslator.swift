//
//  NVTranslator.swift
//  NavajoKit
//
//  Created by Daniel Gump on 1/5/25.
//

import CoreML
import Foundation

///Core class for translation tasks
public class NVTranslator {

	///Singleton
	@MainActor
	public static let shared = NVTranslator()

	///Array of single words, constructed from NVSingleWords.csv
	public var lexiconList: [NVWord] = []
	///Array of compound words, constructed from NVCompoundWords.csv
	public var compoundLexiconList: [NVCompoundWord] = []

	private var debug = false

	private let encoder: NavajoEncoder
	private let decoder: NavajoDecoder
	private let maxLen = 128

	/**
		Initializer

		- Parameters:
			- debug: activate console logging
	 */
	public init(debug: Bool = false) {

		self.debug = debug

		if debug {
			print("Start loading lexicon...")
		}

		let words = Self.loadWords()

		lexiconList = words.0
		compoundLexiconList = words.1

		if debug {
			print("Lexicon loaded.")
		}

		let config = MLModelConfiguration()
		config.computeUnits = .all //.cpuAndNeuralEngine

		if debug {
			print("Loading transformer models...")
		}

		encoder = try! NavajoEncoder(configuration: config)
		decoder = try! NavajoDecoder(configuration: config)

		if debug {
			print("... Done.")
		}

	}

	//MARK: Functions

	/**
		Direct translation of a single word

		- Parameters:
			- word: The untranslated Navajo tagged word object
		- Returns: Modified object with an English translation applied
	 */
	public func translate(word: NVTaggedWord) -> NVTaggedWord {

		let lower = word.token.lowercased()

		//Get list of all matching Navajo words, regardless of POS
		let trans: [NVWord] = lexiconList.filter({
			return $0.navajo == lower
		})

		if trans.count == 0 {
			return NVTaggedWord(
				token: word.token,
				label: word.label,
				translation: nil
			)
		}

		var filteredTrans: [NVWord] = []

		//Narrow down list of matching Navajo words to correct POS
		switch word.label {

			case "NPostp", "NObj", "NSub":
				filteredTrans = trans.filter({
					return $0.partOfSpeech == "N"
				})

			case "ProSub":
				filteredTrans = trans.filter({
					return $0.partOfSpeech == "ProSub" || $0.partOfSpeech == "ProDem"
				})

			case "ProPostp", "ProObj":
				filteredTrans = trans.filter({
					return $0.partOfSpeech == "ProPostp" || $0.partOfSpeech == "ProObj" || $0.partOfSpeech == "ProDem"
				})

			default:
				filteredTrans = trans.filter({
					return $0.partOfSpeech == word.label
				})

		}

		if filteredTrans.count > 0 {

			//Return word with direct translation
			return NVTaggedWord(
				token: word.token,
				label: word.label,
				translation: filteredTrans.first
			)
		}

		//Return guessed translation
		return NVTaggedWord(
			token: word.token,
			label: "\(word.label) -> \(trans.first?.partOfSpeech ?? "")",
			translation: trans.first,
			isFallback: true
		)
	}

	/**
		Direct translation for a series of words with the option to identify compound words during the translation process

		- Parameters:
			- words: The Navajo tagged word object array to replace with its English equivalents
			- combiningCompounds: Identify and merge Navajo compound words to properly translate them as groups
		- Returns: Modified array of objects with an English translations applied
	 */
	public func translate(words: [NVTaggedWord], combiningCompounds: Bool = false) -> [NVTaggedWord] {

		var words = words.map({ return translate(word: $0) })

		if !combiningCompounds {
			return words
		}

		for i in 0..<words.count {

			let maxLength = words.count - i

			//no need to check for compounds
			if maxLength <= 1 {
				continue
			}

			//Find all possible matches by first word
			let compounds = compoundLexiconList.filter({

				return $0.words.first?.navajo.lowercased() == words[i].token.lowercased() && $0.words.count <= maxLength

			})

			//no matches
			if compounds.count == 0 {
				continue
			}

			for compound in compounds {

				let c = compound.words.map({ return $0.navajo }).joined(separator: " ")
				let max = i + compound.words.count
				let w = words[i..<max].map({ return $0.token }).joined(separator: " ")

				//Compound word match
				if c.lowercased() == w.lowercased() {

					var nv = words[i].translation ?? compound.words.first
					words[i].token = w
					words[i].label = compound.partOfSpeech
					nv?.english = compound.english
					nv?.proper = compound.proper
					nv?.validated = compound.validated
					words[i].translation = nv

					for j in (i+1)..<max {
						words[j].token = "_"
					}
					break
				}
			}

		}

		return words.filter({ return $0.token != "_" })
	}

	public func translate(_ text: String, tokenizer: NVTokenizer) -> String {

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
		let encOutput = try! encoder.prediction(input: encInput)
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
			let decOutput = try! decoder.prediction(input: decInput)

			let logits = decOutput.logits
			let timestep = decoded.count - 1

			let nextToken = argmax(logits: logits, timestep: timestep)

			//print("timestep: \(timestep), token: \(nextToken)")

			if nextToken == NVTokenizer.EOS { break }

			decoded.append(nextToken)
		}

		let filtered = decoded.dropFirst().prefix(while: { $0 != NVTokenizer.EOS })
		return tokenizer.decode(tokens: Array(filtered))
	}

	private func argmax(logits: MLMultiArray, timestep: Int) -> Int {

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

	private nonisolated static func loadWords() -> ([NVWord], [NVCompoundWord]) {

		var loadedWords: [NVWord] = []
		var loadedCompoundWords: [NVCompoundWord] = []

		let parsedWordsCSV = NVTranslator.loadCSV(named: "NVSingleWords")
		let parsedCompoundWordsCSV = NVTranslator.loadCSV(named: "NVCompoundWords")

		let wordsTitle = parsedWordsCSV.first!.map({ return String($0) })
		let wordsBody = parsedWordsCSV.dropFirst()

		let compoundWordsTitle = parsedCompoundWordsCSV.first!.map({ return String($0) })
		let compoundWordsBody = parsedCompoundWordsCSV.dropFirst()

		//Process single words
		for row in wordsBody {

			var word: [String: String] = [:]
			for i in 0..<row.count {
				if i < wordsTitle.count && !row[i].isEmpty {
					word[wordsTitle[i]] = row[i]
				}
			}

			if let token = word["TOKENS"],
				var label = word["LABELS"],
				let english = word["english"] {

				//print("Row: \(word.debugDescription)")

				switch label {
					case "NPostp", "NObj", "NSub":
						label = "N"
					default:
						break
				}

				let word = NVWord(
					navajo: token,
					english: english,
					partOfSpeech: label,
					validated: word["validated"] == "TRUE",
					aspect: NVAspect(rawValue: word["aspect"]),
					subject: NVInflection(
						person: NVPerson(rawValue: word["subject-person"]),
						plural: NVPlurality(rawValue: word["subject-plural"])),
					object: NVInflection(
						person: NVPerson(rawValue: word["object-person"]),
						plural: NVPlurality(rawValue: word["object-plural"])),
					infinitive: word["infinitive"],
					proper: word["proper"] == "TRUE",
					prefix: word["prefix"],
					stem: word["stem"],
					suffix: word["suffix"],
					notes: word["notes"]
				)

				loadedWords.append(word)
			}
		}

		//Process compound words
		for row in compoundWordsBody {

			var word: [String: String] = [:]
			for i in 0..<row.count {
				if i < compoundWordsTitle.count && !row[i].isEmpty {
					word[compoundWordsTitle[i]] = row[i]
				}
			}

			if let token = word["TOKENS"],
				let label = word["LABELS"],
				let english = word["english"],
				let partOfSpeech = word["part-of-speech"] {

				//Get all tokens that exist within the token field
				let tokens = token.split(separator: ",").map({

					return String($0).trimmingCharacters(in: .whitespacesAndNewlines)
				})
				//Get all labels that exist within the label field
				let labels = label.split(separator: ",").map({

					//Ignore cases
					let l = String($0).trimmingCharacters(in: .whitespacesAndNewlines)
					switch l {
						case "NPostp", "NObj", "NSub":
							return "N"
						case "ProPostp", "ProObj", "ProSub":
							return "Pro"
						default:
							return l
					}

				})

				//Must have matching token and label array lengths
				if tokens.count != labels.count {
					continue
				}

				var words: [NVWord] = []

				for i in 0..<tokens.count {

					if let w = loadedWords.filter({

						//Ignore cases
						var pos = $0.partOfSpeech
						switch pos {
							case "NPostp", "NObj", "NSub":
								pos = "N"
							case "ProPostp", "ProObj", "ProSub":
								pos = "Pro"
							default:
								break
						}

						return $0.navajo == tokens[i] && pos == labels[i]

					}).first {

						words.append(w)

					} else {

						words.append(NVWord(navajo: tokens[i], english: "", partOfSpeech: labels[i], validated: false))

					}
				}

				//TODO: Handle proper case for noun or pronoun

				let word = NVCompoundWord(
					words: words,
					english: english,
					partOfSpeech: partOfSpeech,
					proper: word["proper"] == "TRUE"
				)

				loadedCompoundWords.append(word)
			}
		}

		return (loadedWords, loadedCompoundWords)
	}

	///Load a CSV file from the local project name, handle quoted fields
	public nonisolated static func loadCSV(named: String) -> [[String]] {

		var data: [[String]] = []

		if let path = Bundle.navajoKit.path(forResource: named, ofType: "csv") {
			let url = URL(fileURLWithPath: path)

			do {
				let rows = try String(contentsOf: url, encoding: .utf8).components(separatedBy: .newlines)

				for row in rows {

					//If there are no quotes, parse as is
					if !row.contains("\"") {

						let tokenized = row.split(separator: ",", omittingEmptySubsequences: false).map({ return String($0) })

						data.append(tokenized)
						continue
					}

					//Parse by character if anything is quoted
					var values: [String] = []
					var currentField = ""
					var insideQuotes = false

					for char in row {

						switch char {
							case "\"":
								insideQuotes.toggle()

							case ",":
								if insideQuotes {
									currentField.append(char)
								} else {
									values.append(currentField)
									currentField = ""
								}

							default:
								currentField.append(char)
						}

					}

					if !currentField.isEmpty {
						values.append(currentField)
					}

					data.append(values)
				}

			} catch let error as NSError {

				print("Error loading CSV: \(error.debugDescription)")
			}

		}

		return data
	}
}
