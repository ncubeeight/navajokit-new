//
//  NVInflection.swift
//  Navajo Translator
//
//  Created by Daniel Gump on 1/21/25.
//

///Representation of grammatical details for subject or object of several parts of speech
public struct NVInflection: Codable, Sendable {
	///Person for verb or possession
	public let person: NVPerson?
	///Plurality for verb or possession
	public let plural: NVPlurality?

	public init(person: NVPerson? = .unspecified, plural: NVPlurality? = .any) {

		self.person = person
		self.plural = plural
	}

	public func getInflection() -> String {

		var inflection = ""

		switch person {
			case .first:
				inflection = "1"
			case .second:
				inflection = "2"
			case .third:
				inflection = "3"
			case .fourth:
				inflection = "4"
			case .fourthO:
				inflection = "3(O)"
			case .fourthA:
				inflection = "3(A)"
			case .fourthI, .indefinite:
				inflection = "3(I)"
			case .firstOrSecond:
				inflection = "1/2"
			case .reciprocal:
				inflection = "Recip"
			case .reflexive:
				inflection = "Refl"
			case .spatial:
				inflection = "Spat"
			default: //.unspecified
				return ""
		}

		switch plural {
			case .singular:
				inflection += "S"
			case .singularOrDual:
				inflection += "SD"
			case .dual:
				inflection += "D"
			case .dualOrPlural:
				inflection += "DP"
			case .plural:
				inflection += "P"
			default: //.any
				break
		}

		return inflection
	}
}
