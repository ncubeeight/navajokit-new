//
//  NVPerson.swift
//  NavajoKit
//
//  Created by Daniel Gump on 1/19/25.
//

///Person applied to several parts-of-speech, both subjects and objects
public enum NVPerson: String, Codable {

	case first
	case second
	case third

	///Similar to third but helps clarify syntactic ambiguity or for nebulous entities
	case fourth
	///Specifically objects (generally humans) in fourth person
	case fourthO
	///Specifically areas (any anyone in them) in fourth person
	case fourthA
	///Indefinite fourth person
	case fourthI

	///Geographic or locational references
	case spatial
	///References with returned effects
	case reciprocal
	///e.g. myself, yourself, ourselves, yourselves, himself, herself, etc.
	case reflexive
	///Dual or plural references that can be we/us or you
	case firstOrSecond
	///Could references multiple subjects or objects
	case indefinite
	
	///Fallback
	case unspecified

	///Initializer for raw strings
	public init?(rawValue: String) {

		switch rawValue.lowercased() {
			case "first", "1", "1st": self = .first
			case "second", "2", "2nd": self = .second
			case "third", "3", "3rd": self = .third
			case "fourth", "4", "4th": self = .fourth
			case "fourtho", "4o", "4tho": self = .fourthO
			case "fourtha", "4a", "4tha": self = .fourthA
			case "fourthi", "4i", "4thi": self = .fourthI
			case "spatial", "spat", "sp": self = .spatial
			case "reciprocal", "recip": self = .reciprocal
			case "reflexive", "reflex", "refl": self = .reflexive
			case "firstorsecond", "12", "1st/2nd": self = .firstOrSecond
			case "indefinite", "indef": self = .indefinite
			default: self = .unspecified
		}

	}

	///Custom initizer to handle nil cases
	public init(rawValue: String?) {

		if let raw = rawValue {
			self = Self(rawValue: raw) ?? .unspecified
		} else {
			self = .unspecified
		}
	}

	///Initializer for decodin from JSON objects
	public init(from decoder: Decoder) throws {

		let container = try decoder.singleValueContainer()
		self = .init(rawValue: try? container.decode(String.self))
	}	

}
