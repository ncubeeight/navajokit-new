//
//  NVAspect.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/20/25.
//

public enum NVAspect: String, Codable {
	case future, imperfective, iterative, optative, perfective, progressive, unspecified

	public init(rawValue: String?) {

		switch rawValue?.lowercased() {
			case "perfective", "perfect", "past", "perf": self = .perfective
			case "imperfective", "imperfect", "present", "impf": self = .imperfective
			case "future", "fut": self = .future
			case "iterative", "repetitive", "iter", "rep": self = .iterative
			case "optative", "opt": self = .optative
			case "progressive", "prog": self = .progressive
			default: self = .unspecified
		}

	}

	public init(from decoder: Decoder) throws {

		let container = try decoder.singleValueContainer()
		self = .init(rawValue: try? container.decode(String.self))
	}	

}
