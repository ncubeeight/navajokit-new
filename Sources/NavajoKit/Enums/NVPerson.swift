//
//  NVPerson.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/19/25.
//

public enum NVPerson: String, Codable {
	case first, second, third, fourth, spatial, firstOrSecond, reciprocal, reflexive, unspecified, indefinite

	public init(rawValue: String?) {

		switch rawValue?.lowercased() {
			case "first", "1", "1st": self = .first
			case "firstOrSecond", "12", "1st/2nd": self = .firstOrSecond
			case "second", "2", "2nd": self = .second
			case "third", "3", "3rd": self = .third
			case "fourth", "4", "4th": self = .fourth
			case "spatial", "spat", "sp": self = .spatial
			case "reciprocal", "recip": self = .reciprocal
			case "reflexive", "reflex", "refl": self = .reflexive
			case "indefinite", "indef": self = .indefinite
			default: self = .unspecified
		}

	}

	public init(from decoder: Decoder) throws {

		let container = try decoder.singleValueContainer()
		self = .init(rawValue: try? container.decode(String.self))
	}	

}
