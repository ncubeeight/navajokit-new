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

		///Treat the standard apostrophe (0x27) as the glottal stop character
		public static let aposAsGlottalStop = Options(rawValue: 1 << 0)
		///Ignore case when tokenizing
		public static let caseInsensitive = Options(rawValue: 1 << 1)
		///Remove all digits from the text
		public static let stripDigits = Options(rawValue: 1 << 2)
		///Include punctuations as their own tokens
		public static let tokenizePunctuation = Options(rawValue: 1 << 3)
		///Include whitespaces as their own tokens
		public static let tokenizeWhitespace = Options(rawValue: 1 << 4)
		///Strip implied glottal stops from words leading with vowels
		public static let stripLeadingGlottalStops = Options(rawValue: 1 << 5)
	}

	///Divisions of the text string to tokenize
	public enum Unit: Int {
		case syllable, word, sentence, paragraph
	}

	///MARK: Private let

	///Grapheme shortcuts to expand in the appreviated syllable list
	private let graphemeList: [String: [String]] = [
		"A": ["a", "aa", "á", "áa", "áá", "ą", "ąą", "ą́", "ą́ą", "ą́ą́"],
		"E": ["e", "ee", "é", "ée", "éé", "ę", "ęę", "ę́", "ę́ę", "ę́ę́"],
		"I": ["i", "ii", "í", "íi", "íí", "į", "įį", "į́", "į́į", "į́į́"],
		"O": ["o", "oo", "ó", "óo", "óó", "ǫ", "ǫǫ", "ǫ́", "ǫ́ǫ", "ǫ́ǫ́"],
		"C": ["ʼ", "b", "ch", "d", "g", "gh", "h", "k", "l", "ł", "m", "n", "s", "sh", "t", "z", "zh"]
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
	public func tokenize(text: String, unit: Unit, options: NVTokenizer.Options? = []) -> (String, [Range<String.Index>]) {

		var string = text
		let options = options ?? []

		if options.contains(.aposAsGlottalStop) {
			string = string.replacingOccurrences(of: "'", with: "ʼ").replacingOccurrences(of: "’", with: "ʼ")
		}
		if options.contains(.stripDigits) {
			string = string.components(separatedBy: .decimalDigits).joined()
		}

		switch unit {

			case .syllable:
				if options.contains(.caseInsensitive) {
					return (string, syllables(for: string.lowercased(), options: options))
				} else {
					return (string, syllables(for: string, options: options))
				}

			case .word:
				if options.contains(.caseInsensitive) {
					return (string, words(for: string.lowercased(), options: options))
				} else {
					return (string, words(for: string, options: options))
				}

			case .sentence:
				return (string, sentences(for: string, options: options))

			case .paragraph:
				return (string, paragraphs(for: string, options: options))

		}

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

		//Run a final pass to strip leading glottal stops
		if options.contains(.stripLeadingGlottalStops) {

			for (index, range) in wordRanges.enumerated() {
				if string[range.lowerBound] == "ʼ" {
					wordRanges[index] = string.index(range.lowerBound, offsetBy: 1)..<range.upperBound
				}
			}

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
