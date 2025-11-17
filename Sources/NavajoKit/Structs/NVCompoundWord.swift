//
//  NVCompoundWord.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 3/27/25.
//

///Representation of a several Navajo words that translate into a compound word or phrase
public struct NVCompoundWord {
	///Component words
	public let words: [NVWord]
	///English translation of compound word
	public let english: String
	///Grammatical part of speech for entire compound word
	public let partOfSpeech: String
	///Whether or not the translation has been validated from a reliable source
	public let validated: Bool?
	///Proper noun
	public let proper: Bool?

	public init(words: [NVWord], english: String, partOfSpeech:String, validated: Bool, proper: Bool) {

		self.words = words
		self.english = english
		self.partOfSpeech = partOfSpeech
		self.validated = validated
		self.proper = proper
	}

	public var word: NVWord {
		get {

			return NVWord(navajo: words.map({ return $0.navajo }).joined(separator: " "), english: english, partOfSpeech: partOfSpeech, validated: validated ?? false, aspect: nil, subject: nil, object: nil, infinitive: nil, proper: proper, prefix: nil, stem: nil, suffix: nil, notes: nil)

		}
	}

	public var debugDescription: String {
		get {
			var desc = "Navajo: \(words.map({ return $0.navajo }).joined(separator: " "))"
			desc += ", English: \(english)"
			desc += ", Part-of-speech: \(partOfSpeech)"
			desc += ", Validated: \((validated ?? false) ? "TRUE" : "FALSE")"
			desc += ", Proper: \((proper ?? false) ? "TRUE" : "FALSE")"

			return desc
		}
	}
}
