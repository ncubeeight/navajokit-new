//
//  NVInflection.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/21/25.
//

///Representation of grammatical details for subject or object of several parts of speech
public struct NVInflection: Codable {
	///Person for verb or possession
	public let person: NVPerson?
	///Plurality for verb or possession
	public let plural: NVPlurality?
}
