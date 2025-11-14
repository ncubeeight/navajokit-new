//
//  NVWordToken.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 7/23/25.
//

public struct NVWordToken: Equatable {
	public var token: String
	public var adjustedToken: String
	public var pos: String?
	public var translation: String?
	public var person: NVPerson?
	public var plurality: NVPlurality?
	public var transitive: Bool?
	public var aspect: String?
	public var infinitive: String?
	public var components: [NVWordToken] = []
}
