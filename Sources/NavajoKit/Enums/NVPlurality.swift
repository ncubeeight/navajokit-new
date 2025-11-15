//
//  NVPlurality.swift
//  NavajoKit
//
//  Created by Daniel Gump on 1/19/25.
//

///Plurality applied to several parts-of-speech, both subjects and objects
public enum NVPlurality: String, Codable {

	case singular
	case dual
	///Distributive plural (i.e. 3 or more)
	case plural

	///Third and fourth person verbs group singular and dual subjects
	case singularOrDual
	///Many prefixes combine dual and distributive plural
	case dualOrPlural
	
	case any

	///Initializer for raw strings
	public init?(rawValue: String) {

		switch rawValue.lowercased() {
			case "singular", "1", "s": self = .singular
			case "dual", "duoplural", "2", "d": self = .dual
			case "plural", "distributive", "distributiveplural", "3", "3+", "p": self = .plural
			case "singularordual", "singularorduoplural", "12", "sd": self = .singularOrDual
			case "dualorplural", "23", "dp": self = .dualOrPlural
			default: self = .any
		}

	}

	///Custom initizer to handle nil cases
	public init(rawValue: String?) {

		if let raw = rawValue {
			self = Self(rawValue: raw) ?? .any
		} else {
			self = .any
		}
	}

	///Initializer for decodin from JSON objects
	public init(from decoder: Decoder) throws {

		let container = try decoder.singleValueContainer()
		self = .init(rawValue: try? container.decode(String.self))
	}
}
