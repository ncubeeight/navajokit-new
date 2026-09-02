//
//  TaggedWord.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/2/25.
//

///Word with part-of-speech tag applied
public struct NVTaggedWord: Sendable {
	///Navajo word
	public var token: String
	//Part-of-speech
	public var label: String
	//English version
	public var translation: NVWord?
	//No direct match by part-of-speech, used direct word match
	public var isFallback: Bool = false

	public init(token: String, label: String, translation: NVWord? = nil, isFallback: Bool = false) {

		self.token = token
		self.label = label
		self.translation = translation
		self.isFallback = isFallback
	}
}
