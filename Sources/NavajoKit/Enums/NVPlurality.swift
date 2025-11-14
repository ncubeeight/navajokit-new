//
//  NVPlurality.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/19/25.
//

public enum NVPlurality: String, Codable {
	case singular, dual, plural, singularOrDual, dualOrPlural, any

	public init(rawValue: String?) {

		switch rawValue?.lowercased() {
			case "singular", "1", "s": self = .singular
			case "dual", "duoplural", "pair", "2", "d": self = .dual
			case "plural", "distributive", "distributiveplural", "3", "3+", "p": self = .plural
			case "singularordual", "singularorduoplural", "12", "sd": self = .singularOrDual
			case "dualorplural", "23", "dp": self = .dualOrPlural
			default: self = .any
		}

	}

	public init(from decoder: Decoder) throws {

		let container = try decoder.singleValueContainer()
		self = .init(rawValue: try? container.decode(String.self))
	}
}
