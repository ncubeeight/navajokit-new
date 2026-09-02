//
//  NVAspect.swift
//  NavajoKit
//
//  Created by Daniel Gump on 1/20/25.
//

///Verb aspects/tenses
public enum NVAspect: String, Codable, Sendable {

	///Roughly equivalent to past tense in English
	case perfective
	///Roughly equivalent to present tense in English
	case imperfective
	///Roughly equivalent to future aspect/tense in English
	case future
	///Roughly equivalent to present progressive tense in English
	case progressive
	///Repeated actions
	case iterative
	///Possible actions
	case optative
	
	///Fallback
	case unspecified

	///Initializer for raw strings
	public init?(rawValue: String) {

		switch rawValue.lowercased() {
			case "perfective", "perfect", "past", "perf": self = .perfective
			case "imperfective", "imperfect", "present", "impf": self = .imperfective
			case "future", "fut": self = .future
			case "iterative", "repetitive", "iter", "rep": self = .iterative
			case "optative", "opt": self = .optative
			case "progressive", "prog": self = .progressive
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

	///Initializer for decoding from JSON objects
	public init(from decoder: Decoder) throws {

		let container = try decoder.singleValueContainer()
		self = .init(rawValue: try? container.decode(String.self))
	}	

}
