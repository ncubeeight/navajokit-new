//
//  NVLexicon.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/5/25.
//

import Foundation

public class NVLexicon {

	public var lexiconList: [NVWord] = []
	public var compoundLexiconList: [NVCompoundWord] = []

	public init() {
		print("Start loading lexicon...")
		loadWords()
		loadCompoundWords()
		print("Done.")
	}

	//MARK: Functions

	public func replace(_ tag: NVTaggedWord) -> NVTaggedWord {

		let lower = tag.token.lowercased()

		//Get list of all matching Navajo words, regardless of POS
		let trans: [NVWord] = lexiconList.filter({
			return $0.navajo == lower
		})

		if trans.count == 0 {
			return NVTaggedWord(
				token: tag.token,
				label: tag.label,
				translation: nil
			)
		}

		var filteredTrans: [NVWord] = []

		//Narrow down list of matching Navajo words to correct POS
		switch tag.label {

			case "NAdp", "NObj", "NRel", "NSub":
				filteredTrans = trans.filter({
					return $0.partOfSpeech == "N"
				})

			case "ProRel", "ProSub":
				filteredTrans = trans.filter({
					return $0.partOfSpeech == "ProSub" || $0.partOfSpeech == "ProDem"
				})

			case "ProAdp", "ProObj":
				filteredTrans = trans.filter({
					return $0.partOfSpeech == "ProAdp" || $0.partOfSpeech == "ProObj" || $0.partOfSpeech == "ProDem"
				})

			default:
				filteredTrans = trans.filter({
					return $0.partOfSpeech == tag.label
				})

		}

		if filteredTrans.count > 0 {

			//Return word with direct translation
			return NVTaggedWord(
				token: tag.token,
				label: tag.label,
				translation: filteredTrans.first
			)
		}

		//Return guessed translation
		return NVTaggedWord(
			token: tag.token,
			label: "\(tag.label) -> \(trans.first?.partOfSpeech ?? "")",
			translation: trans.first,
			isFallback: true
		)
	}

	public func replace(_ words: [NVTaggedWord], combiningCompounds: Bool = false) -> [NVTaggedWord] {

		var words = words.map({ return replace($0) })

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

	private func loadWords() {

		let parsedCSV = NVLexicon.loadCSV(named: "NVLexicon")

		let title = parsedCSV.first!.map({ return String($0) })
		//print("Title: \(title.debugDescription)")

		let body = parsedCSV.dropFirst()

		for row in body {

			var word: [String: String] = [:]
			for i in 0..<row.count {
				if i < title.count && !row[i].isEmpty {
					word[title[i]] = row[i]
				}
			}

			if let token = word["TOKENS"],
				var label = word["LABELS"],
				let english = word["english"] {

				//print("Row: \(word.debugDescription)")

				switch label {
					case "NAdp", "NObj", "NRel", "NSub":
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

				self.lexiconList.append(word)
			}
		}

	}

	private func loadCompoundWords() {

		let parsedCSV = NVLexicon.loadCSV(named: "NVCompoundWords")

		let title = parsedCSV.first!.map({ return String($0) })
		//print("Title: \(title.debugDescription)")

		let body = parsedCSV.dropFirst()

		for row in body {

			var word: [String: String] = [:]
			for i in 0..<row.count {
				if i < title.count && !row[i].isEmpty {
					word[title[i]] = row[i]
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
						case "NAdp", "NObj", "NRel", "NSub":
							return "N"
						case "ProAdp", "ProObj", "ProRel", "ProSub":
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

					if let w = lexiconList.filter({

						//Ignore cases
						var pos = $0.partOfSpeech
						switch pos {
							case "NAdp", "NObj", "NRel", "NSub":
								pos = "N"
							case "ProAdp", "ProObj", "ProRel", "ProSub":
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
					validated: word["validated"] == "TRUE",
					proper: word["proper"] == "TRUE"
				)

				self.compoundLexiconList.append(word)
			}
		}

	}

	///Load a CSV file from the local project name, handle quoted fields
	static func loadCSV(named: String) -> [[String]] {

		var data: [[String]] = []

		if let path = Bundle.main.path(forResource: named, ofType: "csv") {
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
