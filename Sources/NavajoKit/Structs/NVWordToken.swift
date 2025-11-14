//
//  NVWordToken.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 7/23/25.
//

public struct NVWordToken: Equatable {
	var token: String
	var adjustedToken: String
	var pos: String?
	var translation: String?
	var person: NVPerson?
	var plurality: NVPlurality?
	var transitive: Bool?
	var aspect: String?
	var infinitive: String?
	var components: [NVWordToken] = []
}
