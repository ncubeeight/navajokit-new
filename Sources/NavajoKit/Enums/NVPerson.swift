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
	public init(rawValue: String?) {

		switch rawValue?.lowercased() {
			case "first", "1", "1st": self = .first
			case "second", "2", "2nd": self = .second
			case "third", "3", "3rd": self = .third
			case "fourth", "4", "4th": self = .fourth
			case "spatial", "spat", "sp": self = .spatial
			case "reciprocal", "recip": self = .reciprocal
			case "reflexive", "reflex", "refl": self = .reflexive
			case "firstOrSecond", "12", "1st/2nd": self = .firstOrSecond
			case "indefinite", "indef": self = .indefinite
			default: self = .unspecified
		}

	}

	///Initializer for decodin from JSON objects
	public init(from decoder: Decoder) throws {

		let container = try decoder.singleValueContainer()
		self = .init(rawValue: try? container.decode(String.self))
	}	

}
