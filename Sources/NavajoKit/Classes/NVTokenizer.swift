//
//  NVTokenizer.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/29/24.
//

import Foundation

///Tokenizing a string of Navajo text into specified unit lengths with optional settings
public class NVTokenizer {

	///Singleton
	@MainActor
	public static let shared = NVTokenizer()

	///Customizations for the tokenization process
	public struct Options: OptionSet, Sendable {
		public let rawValue: Int

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		///Ignore case when tokenizing
		public static let caseInsensitive = Options(rawValue: 1 << 0)
		///Remove all digits from the text
		public static let stripDigits = Options(rawValue: 1 << 1)
		///Strip implied glottal stops from words leading with vowels
		public static let stripLeadingGlottalStops = Options(rawValue: 1 << 2)
		///Include punctuations as their own tokens
		public static let tokenizePunctuation = Options(rawValue: 1 << 3)
		///Include whitespaces as their own tokens
		public static let tokenizeWhitespace = Options(rawValue: 1 << 4)
	}

	///Divisions of the text string to tokenize
	public enum Unit: Int {
		case syllable, word, sentence, paragraph
	}

	public var vocab: [String: Int] = [:]
	public var idToPiece: [Int: String] = [:]

	public static let BOS = 1
	public static let EOS = 2
	public static let UNK = 3

	///Fixes to common erroneous unicode characters
	public static let unicodeMap: [String: [String]] = [

		// LOWERCASE - plain nasal
		"ą": ["a̧", "a̦", "a̜", "ạ"],
		"ę": ["ȩ", "e̦", "e̜", "ẹ", "ȩ"],
		"į": ["i̧", "i̦", "i̜", "ị"],
		"ǫ": ["o̧", "o̦", "o̜", "ọ"],

		// LOWERCASE - nasal + acute
		"ą́": ["á̧", "á̦", "á̜", "ạ́", "á̧", "á̦", "á̜", "ạ́"],
		"ę́": ["ȩ́", "é̦", "é̜", "ẹ́", "ȩ́", "é̦", "é̜", "ẹ́", "ȩ́"],
		"į́": ["í̧", "í̦", "í̜", "ị́", "í̧", "í̦", "í̜", "ị́"],
		"ǫ́": ["ó̧", "ó̦", "ó̜", "ọ́", "ó̧", "ó̦", "ó̜", "ọ́"],

		// UPPERCASE - plain nasal
		"Ą": ["A̧", "A̦", "A̜", "Ạ"],
		"Ę": ["Ȩ", "E̦", "E̜", "Ẹ", "Ȩ"],
		"Į": ["I̧", "I̦", "I̜", "Ị"],
		"Ǫ": ["O̧", "O̦", "O̜", "Ọ"],

		// UPPERCASE - nasal + acute
		"Ą́": ["Á̧", "Á̦", "Á̜", "Ạ́", "Á̧", "Á̦", "Á̜", "Ạ́"],
		"Ę́": ["Ȩ́", "É̦", "É̜", "Ẹ́", "Ȩ́", "É̦", "É̜", "Ẹ́"],
		"Į́": ["Í̧", "Í̦", "Í̜", "Ị́", "Í̧", "Í̦", "Í̜", "Ị́"],
		"Ǫ́": ["Ó̧", "Ó̦", "Ó̜", "Ọ́", "Ó̧", "Ó̦", "Ó̜", "Ọ́"],

		// GLOTTAL STOP
		"ʼ": ["'", "’", "‘", "`"],
	]

	///Match some spelling variants to make models more compact
	public static let spellingMap: [String: String] = [

		// LOWERCASE
		"nt": "nit",
		"ńt": "nít",
		"jt": "jit",

		// UPPERCASE
		"Nt": "Nit",
		"Ńt": "Nít",
		"Jt": "Jit",

	]

	///MARK: Private let

	///Grapheme shortcuts to expand in the appreviated syllable list
	private let graphemeList: [String: [String]] = [
		"A": ["a", "aa", "aá", "á", "áa", "áá", "ą", "ąą", "ąą́", "ą́", "ą́ą", "ą́ą́"],
		"E": ["e", "ee", "eé", "é", "ée", "éé", "ę", "ęę", "ęę́", "ę́", "ę́ę", "ę́ę́"],
		"I": ["i", "ii", "ií", "í", "íi", "íí", "į", "įį", "įį́", "į́", "į́į", "į́į́"],
		"O": ["o", "oo", "oó", "ó", "óo", "óó", "ǫ", "ǫǫ", "ǫǫ́", "ǫ́", "ǫ́ǫ", "ǫ́ǫ́"],
		"C": ["ʼ", "b", "ch", "d", "g", "gh", "h", "j", "k", "l", "ł", "m", "n", "s", "sh", "t", "w", "x", "y", "z", "zh"]
	]

	///MARK: Private var

	///Abbreviated syllable list to be expanded upon class initialization
	private var syllableList: [String] = [

		"ʼA",
		"ʼaan",
		"ʼAC",
		"ʼAhʼ",
		"ʼE",
		"ʼEC",
		"ʼéI",
		"ʼho",
		"ʼI",
		"ʼIC",
		"ʼnA",
		"ʼO",
		"ʼOC",

		"A",
		"AC",
		"aooʼ",

		"bA",
		"bAC",
		"bE",
		"bEC",
		"bI",
		"bIC",
		"bO",
		"bOC",

		"chʼA",
		"chʼAC",
		"chʼE",
		"chʼEC",
		"chʼI",
		"chʼIC",
		"chʼO",
		"chʼOC",
		"chA",
		"chAC",
		"chE",
		"chEC",
		"cheI",
		"chI",
		"chIC",
		"chxA",
		"chxE",
		"chxI",
		"chxO",

		"dA",
		"dAC",
		"dAshʼ",
		"daIʼ",
		"dAo",
		"dE",
		"dEC",
		"dEi",
		"dEshʼ",
		"dI",
		"dIC",
		"dIshʼ",
		"dlA",
		"dlAC",
		"dlE",
		"dlEC",
		"dléí",
		"dlI",
		"dlIC",
		"dlO",
		"dlOC",
		"dO",
		"dOC",
		"dzA",
		"dzAC",
		"dzE",
		"dzEC",
		"dzI",
		"dzIC",
		"dzO",
		"dzOC",

		"E",
		"EC",
		"éí",

		"gA",
		"gAC",
		"gaI",
		"gE",
		"gEC",
		"ghA",
		"ghAC",
		"ghE",
		"ghEC",
		"ghI",
		"ghIC",
		"ghO",
		"ghOC",
		"gI",
		"gIC",
		"gO",
		"gOC",

		"hA",
		"hAC",
		"hE",
		"hEC",
		"hI",
		"hIC",
		"hO",
		"hOC",

		"I",
		"IC",

		"jA",
		"jAC",
		"jE",
		"jEC",
		"jI",
		"jIC",
		"jO",
		"jOC",

		"kʼA",
		"kʼAC",
		"kʼE",
		"kʼEC",
		"kʼI",
		"kʼIC",
		"kʼO",
		"kʼOC",
		"kʼsas",
		"kA",
		"kAC",
		"kaI",
		"kE",
		"kEC",
		"kI",
		"kIC",
		"kO",
		"kOC",
		"kwe",

		"lʼA",
		"lʼE",
		"lʼI",
		"lʼO",
		"lA",
		"lAC",
		"lE",
		"lEC",
		"léiʼ",
		"lI",
		"lIC",
		"lO",
		"lOC",

		"łʼA",
		"łʼE",
		"łʼI",
		"łʼO",
		"łA",
		"łAC",
		"łE",
		"łEC",
		"łI",
		"łIC",
		"łO",
		"łOC",
		"łóóʼn",

		"mA",
		"mAC",
		"mE",
		"mEC",
		"mI",
		"mIC",
		"mO",
		"mOC",

		"nA",
		"naʼii",
		"naaí",
		"nAC",
		"ndA",
		"ndAC",
		"ndE",
		"ndEC",
		"ndI",
		"ndIC",
		"ndO",
		"ndOC",
		"nE",
		"nEC",
		"nei",
		"nI",
		"nIC",
		"nléí",
		"nO",
		"nOC",
		"nteel",
		"ntsaaí",
		"ntsxaaí",

		"O",
		"oosh",

		"sʼná",
		"sA",
		"sAC",
		"sE",
		"sEC",
		"shʼaah",
		"shʼnah",
		"shA",
		"shAC",
		"shE",
		"shEC",
		"shI",
		"shIC",
		"shlEC",
		"shłEC",
		"shO",
		"shOC",
		"sI",
		"sIC",
		"sO",
		"sOC",
		"stʼA",
		"stʼE",
		"stʼees",
		"stʼéí",
		"stA",
		"stAC",
		"stE",
		"stEC",
		"stI",
		"stIC",
		"stO",
		"stOC",
		"stóí",

		"tʼA",
		"tʼAC",
		"tʼE",
		"tʼEC",
		"tʼéi",
		"tʼI",
		"tʼIC",
		"tʼO",
		"tʼOC",
		"tA",
		"tAC",
		"tE",
		"tEC",
		"tI",
		"tIC",
		"tłʼA",
		"tłʼAC",
		"tłʼE",
		"tłʼI",
		"tłʼIC",
		"tłʼO",
		"tłʼOC",
		"tłE",
		"tłEC",
		"tłI",
		"tO",
		"tOC",
		"tsʼA",
		"tsʼAC",
		"tsʼE",
		"tsʼEC",
		"tsʼI",
		"tsʼIC",
		"tsʼO",
		"tsʼOC",
		"tsA",
		"tsAC",
		"tsE",
		"tsEC",
		"tsI",
		"tsIC",
		"tsO",
		"tsOC",
		"tsoI",
		"tsxaaí",
		"tsxooí",

		"wA",
		"wAC",
		"wE",
		"wEC",
		"wI",
		"wIC",
		"wO",
		"wOC",

		"yA",
		"yAʼ",
		"yah",
		"yAC",
		"yE",
		"yEC",
		"yéi",
		"yI",
		"yIC",
		"yįh",
		"yO",
		"yOC",
		"yói",
		"yóí",

		"zʼA",
		"zA",
		"zAC",
		"zE",
		"zEC",
		"zhA",
		"zhAʼ",
		"zhE",
		"zhEʼ",
		"zhI",
		"zhIʼ",
		"zhIn",
		"zhO",
		"zhOʼ",
		"zI",
		"zIC",
		"zO",
		"zOC",
		"zOí",
	]

	//MARK: Init / Deinit

	///Initializer
	public init() {

		for (key, graphemes) in graphemeList {

			for index in (0..<syllableList.count).reversed() {

				if syllableList[index].contains(key) {

					let syl = syllableList.remove(at: index)
					for grapheme in graphemes {
						syllableList.append(syl.replacingOccurrences(of: key, with: grapheme))
					}

				}

			}

		}

		//Sort syllables largest to smallest
		syllableList.sort(by: {
			return $0.count > $1.count
		})

		//Load token definition for transformer
		if let url = Bundle.navajoKit.url(forResource: "vocab", withExtension: "json"),
			let data = try? Data(contentsOf: url) {

			vocab = (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]

			for (k, v) in vocab {
				idToPiece[v] = k
			}
		}

	}

	///Deinitializer
	deinit {

	}

	//MARK: Public functions

	/**
		Tokenize the specified string by units and options

		- Parameters:
			- text: Full text string
			- unit: tokenization unit
			- options: modifications to methodology
		- Returns: Tuple with with string modified by any of the options and an array of tokenization ranges within that string
	*/
	public func tokenize(_ text: String, unit: Unit, options: NVTokenizer.Options? = []) async -> (String, [Range<String.Index>]) {

		let options = options ?? []
		let string = cleanText(text, options: options)

		switch unit {

			case .syllable:
				return (string, syllables(for: string, options: options))

			case .word:
				return (string, words(for: string, options: options))

			case .sentence:
				return (string, sentences(for: string, options: options))

			case .paragraph:
				return (string, paragraphs(for: string, options: options))

		}

	}

	public func encode(_ text: String, options: NVTokenizer.Options? = []) -> [Int] {

		let options = options ?? []
		let string = cleanText(text, options: options)

		let normalized = "▁" + string.replacingOccurrences(of: " ", with: "▁")

		var tokens: [Int] = []

		var i = normalized.startIndex

		while i < normalized.endIndex {

			var end = normalized.endIndex
			var match: String? = nil

			while end > i {

				let piece = String(normalized[i..<end])

				if vocab[piece] != nil {
					match = piece
					break
				}

				end = normalized.index(before:end)
			}

			if let m = match {

				tokens.append(vocab[m]!)
				i = normalized.index(i, offsetBy: m.count)

			} else {

				tokens.append(NVTokenizer.UNK)
				i = normalized.index(after:i)
			}
		}

		return tokens
	}

	public func decode(tokens: [Int]) -> String {

		var text = ""

		for id in tokens {

			guard let piece = idToPiece[id] else { continue }

			if piece == "<eos>" { break }

			text += piece
		}

		text = text.replacingOccurrences(of: "▁", with: " ")

		return text.trimmingCharacters(in: .whitespaces)
	}

	//MARK: Private functions

	///Apply options to properly format the text
	private func cleanText(_ text: String, options: NVTokenizer.Options) -> String {

		var string = text

		//Correct Unicode characters
		for (key, values) in NVTokenizer.unicodeMap {
			for value in values {
				string = string.replacingOccurrences(of: value.decomposedStringWithCanonicalMapping, with: key)
			}
		}

		//Make spelling consistent
		for (key, value) in NVTokenizer.spellingMap {
			string = string.replacingOccurrences(of: value.decomposedStringWithCanonicalMapping, with: key)
		}

		if options.contains(.stripDigits) {
			string = string.components(separatedBy: .decimalDigits).joined()
		}

		if options.contains(.stripLeadingGlottalStops) {

			string = string
				.components(separatedBy: .whitespacesAndNewlines)
				.map({
					return $0.hasPrefix("ʼ") ? String($0.dropFirst()) : $0
				})
				.joined(separator: " ")

		}

		return string
	}

	///Tokenize by syllables, calls word tokenization first
	private func syllables(for string: String, options: NVTokenizer.Options) -> [Range<String.Index>] {

		//Parse words on first pass
		let wordRanges = words(for: string, options: options)

		var syllableRanges: [Range<String.Index>] = []

		//Step backward through each word
		for wordRange in wordRanges {

			//Default to entire word range
			let lowerIndex = wordRange.lowerBound
			var upperIndex = wordRange.upperBound

			while upperIndex > lowerIndex {

				let word = string[lowerIndex..<upperIndex]
				var found = false

				//Search all syllables from a suffix match
				for syl in syllableList {

					//Does the word contain that syllable?
					if word.suffix(syl.count) == syl {

						//Range of syllable
						let li = word.index(upperIndex, offsetBy: -syl.count)

						syllableRanges.append(li..<upperIndex)

						upperIndex = li
						found = true
						break
					}

				}

				if !found {
					break
				}
			}

			if upperIndex > lowerIndex {
				syllableRanges.append(lowerIndex..<upperIndex)
			}
		}

		syllableRanges.sort(by: { $0.lowerBound < $1.lowerBound })

		return syllableRanges
	}

	///Tokenize by words
	private func words(for string: String, options: NVTokenizer.Options) -> [Range<String.Index>] {

		var string = string

		//Parse words on first pass
		if options.contains(.caseInsensitive) {
			string = string.lowercased()
		}

		let range = string.startIndex..<string.endIndex
		var wordRanges: [Range<String.Index>] = []

		var lowerIndex = range.lowerBound
		var upperIndex = range.lowerBound

		while upperIndex < range.upperBound {

			let char = string[upperIndex]

			//Word boundary
			if char.isWhitespace || char.isPunctuation {

				//Add tokenized word to list
				if lowerIndex != upperIndex {
					wordRanges.append(lowerIndex..<upperIndex)
				}

				lowerIndex = upperIndex
				upperIndex = string.index(upperIndex, offsetBy: 1)

				//Add token for word separator
				if (options.contains(.tokenizePunctuation) && char.isPunctuation) || (options.contains(.tokenizeWhitespace) && char.isWhitespace) {

					wordRanges.append(lowerIndex..<upperIndex)
				}

				lowerIndex = upperIndex

			} else {

				//Advance to next character
				upperIndex = string.index(upperIndex, offsetBy: 1)
				
			}
		}

		if lowerIndex < upperIndex {
			wordRanges.append(lowerIndex..<upperIndex)
		}

		return wordRanges
	}

	///Tokenize by sentences
	//TODO: Handle cases where sentences end with trailing quotes.
	private func sentences(for string: String, options: NVTokenizer.Options) -> [Range<String.Index>] {

		let range = string.startIndex..<string.endIndex
		var sentenceRanges: [Range<String.Index>] = []

		var lowerIndex = range.lowerBound
		var upperIndex = range.lowerBound

		let boundaryCharacters: [Character] = [".", "?", "!", ";", "\n", "\t"]

		while upperIndex < range.upperBound {

			let char = string[upperIndex]

			//Sentence boundary
			if boundaryCharacters.contains(char) {

				upperIndex = string.index(upperIndex, offsetBy: 1)

				sentenceRanges.append(lowerIndex..<upperIndex)
				lowerIndex = upperIndex

			} else {

				//Advance to next character
				upperIndex = string.index(upperIndex, offsetBy: 1)
			}
		}

		if lowerIndex < upperIndex {
			sentenceRanges.append(lowerIndex..<upperIndex)
		}

		return sentenceRanges
	}

	///Tokenize by paragraphs
	private func paragraphs(for string: String, options: NVTokenizer.Options) -> [Range<String.Index>] {

		let range = string.startIndex..<string.endIndex
		var paragraphRanges: [Range<String.Index>] = []

		var lowerIndex = range.lowerBound
		var upperIndex = range.lowerBound

		let boundaryCharacters: [Character] = ["\n", "\t"]

		while upperIndex < range.upperBound {

			let char = string[upperIndex]

			//Paragraph boundary
			if boundaryCharacters.contains(char) {

				paragraphRanges.append(lowerIndex..<upperIndex)
				lowerIndex = upperIndex
				upperIndex = string.index(upperIndex, offsetBy: 1)

			} else {

				//Advance to next character
				upperIndex = string.index(upperIndex, offsetBy: 1)
			}
		}

		if lowerIndex < upperIndex {
			paragraphRanges.append(lowerIndex..<upperIndex)
		}

		return paragraphRanges
	}
}
