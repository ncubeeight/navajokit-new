//
//  NVWordToken.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 7/23/25.
//

///Navajo word, its grammatical details, its translation, and any subtoken components
public struct NVWordToken: Equatable {
	///Raw Navajo word or component
	public var token: String
	///Used to represent adjustments to irregular polysynthetic token components
	public var adjustedToken: String
	///Part-of-speech
	public var pos: String?
	///English translation
	public var translation: String?
	///Grammatical person
	public var person: NVPerson?
	///Grammaticl plurality
	public var plurality: NVPlurality?
	///Transitivity of verb
	public var transitive: Bool?
	///Aspect of verb
	public var aspect: String?
	///English infinitive
	public var infinitive: String?
	///Polysynthetic components
	public var components: [NVWordToken] = []
}
