//
//  NVWord.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/19/25.
//

import Foundation

/**
Representation of a single Navajo word with its morphology and other details attached
(Compatible with encoding and decoding for JSON)
*/
public struct NVWord: Codable, Identifiable, Sendable {

	public let id: UUID
	
	///Original Navajo word
	public var navajo: String
	///English translation
	public var english: String
	///Grammatical of speech
	public var partOfSpeech: String
	///Whether or not the word has been validated from a credible source
	public var validated: Bool?
	///Grammatical aspect for verb or word derived from a verb
	public let aspect: NVAspect?
	///Verb subject or noun possessive state
	public let subject: NVInflection?
	///Verb or postposition object
	public let object: NVInflection?
	///English infinitive for verb or word derived from verb
	public let infinitive: String?
	///Proper noun
	public var proper: Bool?
	///Grammatical prefix attached to stem
	public let prefix: String?
	///Word root or derived form
	public let stem: String?
	///Grammatical suffix attached to stem
	public let suffix: String?
	///Additional translation notes
	public let notes: String?

	public init(id: UUID = UUID(), navajo: String, english: String, partOfSpeech: String, validated: Bool, aspect: NVAspect? = nil, subject: NVInflection? = nil, object: NVInflection? = nil, infinitive: String? = nil, proper: Bool? = nil, prefix: String? = nil, stem: String? = nil, suffix: String? = nil, notes: String? = nil) {

		self.id = id
		self.navajo = navajo
		self.english = english
		self.partOfSpeech = partOfSpeech
		self.validated = validated
		self.aspect = aspect
		self.subject = subject
		self.object = object
		self.infinitive = infinitive
		self.proper = proper
		self.prefix = prefix
		self.stem = stem
		self.suffix = suffix
		self.notes = notes
	}

	public func getInflection() -> String {

		var components: [String] = []

		if let subject = subject?.getInflection(), !subject.isEmpty {
			components.append(subject)
		}
		if let object = object?.getInflection(), !object.isEmpty {
			components.append("->")
			components.append(object)
		}

		return components.joined(separator: " ")
	}
}
