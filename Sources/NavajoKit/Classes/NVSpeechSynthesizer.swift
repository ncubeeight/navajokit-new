//
//  NVSpeechSynthesizer.swift
//  NavajoKit
//
//  Created by Daniel Gump on 12/18/25.
//

import AVFoundation

///Generate speech from syllable-tokenized Navajo text
public class NVSpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {

	///Singleton
	@MainActor
	public static let shared = NVSpeechSynthesizer()

	///Adjust the playback speed, range: 0.0 - 1.0
	public var speed: Float = 0.5

	///Getter to check if speech is active
	public var isSpeaking: Bool {
		return _isSpeaking
	}

	///Graphemes as IPA phonetic symbols
	private let graphemeIpaList: [String: String] = [
		"aa": "ɑː",
		"aá": "ɑ˩˥ː",
		"áa": "ɑ˥˩ː",
		"áá": "ɑ˥ː",
		"ąą": "ɑ̃ː",
		"ąą́": "ɑ̃˩˥ː",
		"ą́ą": "ɑ̃˥˩ː",
		"ą́ą́": "ɑ̃˥ː",
		"ee": "eː",
		"eé": "e˩˥ː",
		"ée": "e˥˩ː",
		"éé": "e˥ː",
		"ęę": "ẽː",
		"ęę́": "ẽ˩˥ː",
		"ę́ę": "ẽ˥˩ː",
		"ę́ę́": "ẽ˥ː",
		"ii": "iː",
		"ií": "i˩˥ː",
		"íi": "i˥˩ː",
		"íí": "i˥ː",
		"įį": "ĩː",
		"įį́": "ĩ˩˥ː",
		"į́į": "ĩ˥˩ː",
		"į́į́": "ĩ˥ː",
		"oo": "oː",
		"oó": "o˩˥ː",
		"óo": "o˥˩ː",
		"óó": "o˥ː",
		"ǫǫ": "õː",
		"ǫǫ́": "õ˩˥ː",
		"ǫ́ǫ": "õ˥˩ː",
		"ǫ́ǫ́": "ṍ˥ː",
		"ch": "tʃʰ",
		"dl": "tɬʰ",
		"dz": "ts",
		"gh": "ɣ",
		"hw": "ʍ",
		"kw": "kʷʰ",
		"sh": "ʃ",
		"tł": "tɬʰ",
		"ts": "tsʰ",
		"zh": "ʒ",
		"a": "ɑ",
		"á": "ɑ˥",
		"ą": "ɑ̃",
		"ą́": "ɑ̃˥",
		"e": "e",
		"é": "e˥",
		"ę": "ẽ",
		"ę́": "ẽ˥",
		"i": "i",
		"í": "i˥",
		"į": "ĩ",
		"į́": "ĩ˥",
		"o": "o",
		"ó": "o˥",
		"ǫ": "õ",
		"ǫ́": "õ˥",
		"ʼ": "ʔ",
		"b": "p",
		"d": "t",
		"g": "k",
		"h": "h",
		"j": "tʃʰ",
		"k": "kʰ",
		"l": "l",
		"ł": "ɬ",
		"m": "m",
		"n": "n",
		"p": "p",
		"s": "s",
		"t": "tʰ",
		"w": "w",
		"x": "x",
		"y": "j",
		"z": "z",
	]

	private var _isSpeaking = false

	private let synthesizer = AVSpeechSynthesizer()
	private let tokenizer = NVTokenizer()

	private let options: NVTokenizer.Options

	///Initializer with optional configuration for tokenization
	public init(options: NVTokenizer.Options? = nil) {

		self.options = options ?? [.caseInsensitive, .aposAsGlottalStop, .stripDigits, .stripLeadingGlottalStops, .tokenizePunctuation, .tokenizeWhitespace]

		super.init()

		synthesizer.delegate = self
	}

	deinit {

	}

	///Encode text string into attributed string with IPA references
	public func ipaEncode(text: String) async -> NSMutableAttributedString {

		let (text, ranges) = await tokenizer.tokenize(text: text, unit: .syllable, options: options)

		let attributedText = NSMutableAttributedString(string: "")
		var rawWord = ""
		var encodedWord = ""

		for range in ranges {

			//Current token
			let token = String(text[range])
			//Last character of running text
			let current = token.last ?? " "

			//Add syllable marker to on-going words
			if rawWord.count > 0 && current.isLetter {
				encodedWord.append(".")
			}

			//Process tokens that include letters
			if current.isLetter {

				rawWord += token

				var tokenLower = token.lowercased()

				//Check token for IPA elements
				while tokenLower.count > 0 {

					var found = false

					for grapheme in graphemeIpaList {

						if tokenLower.hasPrefix(grapheme.key) {
							encodedWord.append(grapheme.value)
							tokenLower.removeFirst(grapheme.key.count)
							found = true
							break
						}

					}

					//No matching IPA symbol found, so just add the letter
					if !found {
						encodedWord.append(current)
						tokenLower.removeFirst(1)
					}

				}

			}

			//Not part of a word
			if !current.isLetter {

				//Append and reset encoded word
				if rawWord.count > 0 {
					attributedText.append(ipaWord(raw: rawWord, encoded: encodedWord))
					rawWord = ""
					encodedWord = ""
				}

				//Just append whatever is there
				attributedText.append(NSAttributedString(string: token))

			}

		}

		//Append any remaining word
		if rawWord.count > 0 {
			attributedText.append(ipaWord(raw: rawWord, encoded: encodedWord))
			rawWord = ""
			encodedWord = ""
		}

		return attributedText
	}

	///Speak text with IPA references
	public func speak(ipaText: NSAttributedString) async throws {

		let utterance = AVSpeechUtterance(attributedString: ipaText)
		utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
		utterance.rate = AVSpeechUtteranceDefaultSpeechRate * min(1.0, max(0.0, speed))
		synthesizer.speak(utterance)
	}

	///Stop any current speech, optionally at the end of the current word
	public func stopSpeaking(atWord: Bool = false) {
		synthesizer.stopSpeaking(at: atWord ? .word : .immediate)
	}

	private func ipaWord(raw: String, encoded: String) -> NSAttributedString {

		let attributedString = NSMutableAttributedString(string: raw)

		let glottal = isVowel(raw.first ?? Character("")) ? "ʔ" : ""

		attributedString.addAttribute(
			NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute),
			value: "\(glottal)\(encoded)",
			range: NSRange(location: 0, length: raw.count)
		)

		return attributedString

	}

	private func isVowel(_ character: Character) -> Bool {
		return "aáąą́eéęę́iíįį́oóǫǫ́".contains(character)
	}

	//MARK: AVSpeechSynthesizerDelegate

	//AVSpeechSynthesizerDelegate
	public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {

		_isSpeaking = true
	}

	public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {

		_isSpeaking = false
	}

	public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {

		_isSpeaking = false
	}

}
