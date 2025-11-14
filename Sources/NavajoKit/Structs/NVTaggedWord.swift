//
//  TaggedWord.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/2/25.
//

public struct NVTaggedWord {
	//Word
	public var token: String
	//Part-of-speech
	public var label: String
	//English version
	public var translation: NVWord?
	//No direct match by part-of-speech, used direct word match
	public var isFallback: Bool = false
}
