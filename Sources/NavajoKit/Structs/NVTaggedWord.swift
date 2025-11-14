//
//  TaggedWord.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/2/25.
//

public struct NVTaggedWord {
	//Word
	var token: String
	//Part-of-speech
	var label: String
	//English version
	var translation: NVWord?
	//No direct match by part-of-speech, used direct word match
	var isFallback: Bool = false
}
