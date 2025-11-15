//
//  NVPolysyntheticTokenizer.swift
//  NavajoKit
//
//  Created by Daniel Gump on 7/21/25.
//

import Foundation

///Tokenizing a Navajo word into its subcomponents by language-specific word components
/// > Important: This class is very early in development
public class NVPolysyntheticTokenizer {

	///Singleton
	@MainActor
	public static let shared = NVPolysyntheticTokenizer()

	public struct Options: OptionSet, Sendable {
		public let rawValue: Int

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		///Strip implied glottal stops from words leading with vowels
		static let stripLeadingGlottalStops = Options(rawValue: 1 << 0)
	}

	private let possessivePrefixList: [NVWordToken] = [
		NVWordToken(token: "danihi", adjustedToken: "danihi", translation: "our/your", person: .firstOrSecond, plurality: .plural),
		NVWordToken(token: "danihí", adjustedToken: "danihi", translation: "our/your", person: .firstOrSecond, plurality: .plural),
		NVWordToken(token: "nihi", adjustedToken: "nihi", translation: "our/your", person: .firstOrSecond, plurality: .dual),
		NVWordToken(token: "nihí", adjustedToken: "nihi", translation: "our/your", person: .firstOrSecond, plurality: .dual),
		NVWordToken(token: "shi", adjustedToken: "shi", translation: "my", person: .first, plurality: .singular),
		NVWordToken(token: "shí", adjustedToken: "shi", translation: "my", person: .first, plurality: .singular),
		NVWordToken(token: "ni", adjustedToken: "ni", translation: "your", person: .first, plurality: .singular),
		NVWordToken(token: "ní", adjustedToken: "ni", translation: "your", person: .first, plurality: .singular),
		NVWordToken(token: "bi", adjustedToken: "bi", translation: "his/her/its/their", person: .third),
		NVWordToken(token: "bí", adjustedToken: "bi", translation: "his/her/its/their", person: .third),
		NVWordToken(token: "yi", adjustedToken: "yi", translation: "one's/others'", person: .fourth),
		NVWordToken(token: "yí", adjustedToken: "yi", translation: "one's/others'", person: .fourth),
		NVWordToken(token: "ha", adjustedToken: "ha", translation: "one's/others'", person: .fourth),
		NVWordToken(token: "há", adjustedToken: "ha", translation: "one's/others'", person: .fourth),
		NVWordToken(token: "hw", adjustedToken: "hw", translation: "one's/others'", person: .fourth),
		NVWordToken(token: "a", adjustedToken: "a", person: .indefinite),
		NVWordToken(token: "á", adjustedToken: "a", person: .indefinite),
	]

	//v4 Direct Object
	private let verbDirectObjectList: [String: [String: String]] = [
		"shi": ["person": "1st", "plural": "S"],
		"ni": ["person": "2nd", "plural": "S"],
		"nihi": ["person": "1st/2nd", "plural": "P"],
		"bi": ["person": "3rd"],
		"yi": ["person": "3rd"], //or 4th object?
		"ha": ["person": "Spat"],
		"ho": ["person": "Spat"],
		"a": ["person": "Indef"],
		"adi": ["person": "Reflex"],
		"di": ["person": "Reflex"],
		"ahi": ["person": "Recip"]
	]

	//v8 Subject
	private let verbSubjectList: [String: [String: String]] = [
		"sis": ["person": "1st", "plural": "S", "aspect": "perfect"],
		"sé": ["person": "1st", "plural": "S", "aspect": "perfect"],
		"siid": ["person": "1st", "plural": "P", "aspect": "perfect"],
		"síní": ["person": "2nd", "plural": "S", "aspect": "perfect"],
		"sooh": ["person": "2nd", "plural": "P", "aspect": "perfect"],
		"soo": ["person": "2nd", "plural": "P", "aspect": "perfect"],
		"s": ["person": "3rd", "aspect": "perfect"],
		"z": ["person": "3rd", "aspect": "perfect"],
		"sh": ["person": "1st", "plural": "S", "aspect": "imperfect"],
		"iid": ["person": "1st", "plural": "P", "aspect": "imperfect"],
		"ni": ["person": "2nd", "plural": "S", "aspect": "imperfect"],
		"oh": ["person": "2nd", "plural": "P", "aspect": "imperfect"],
		"oo": ["person": "2nd", "plural": "P", "aspect": "imperfect"],
		"ji": ["person": "4th", "aspect": "imperfect"],
	]

	//v9 Classifier
	private let verbClassifierList: [String: [String: Bool]] = [
		"": ["transitive": false, "reciprocal": false],
		"ł": ["transitive": true, "reciprocal": false],
		"d": ["transitive": false, "reciprocal": true],
		"l": ["transitive": true, "reciprocal": true]
	]

	//Postposition suffixes can be applied to many parts of speech
	private let postpositionSuffixList: [String: String] = [
		"ʼoh": "less than",
		"ʼąą": "beyond",
		"aa": "to",
		"á": "for (the benefit of)",
		"áátis": "over",
		"ááłkʼiis": "alongside",
		"ąąh": "on", //or "beside"
		"ą́ą́h": "passing by",
		"baʼ": "waiting",
		"ba": "used up",
		"chʼa": "scold",
		"chʼijí": "toward", //or "supporting"
		"chʼįʼ": "to, toward",
		"chʼą́ą́h": "blocking",
		"chá": "bunched together",
		"chą́ʼ": "craving",
		"dááh": "before",
		"dą́ą́ʼ": "past time",
		"de": "up",
		"deená": "in exchange for",
		"dę́ę́ʼ": "from (general location/time)",
		"di": "at",
		"diníná": "in opposition to",
		"dóó": "from (specific location/time)",
		"ee": "by means of",
		//"ę́ę-dą́ą́’": "back when",
		"ghá": "through",
		"ghą́ą́h": "attached to",
		"gi": "at (specific location)",
		"góó": "toward", //use with number for date
		"ii’": "inside of", //or "within"
		"iih": "into",
		"ił": "with",
		//"í-jígo": "in the direction of location",
		"ídin": "without",
		"íighah": "by means of (time)",
		"íniiká": "against",
		"íyah": "under", //or "supporting (weight)"
		"jigo": "toward", //or "northward"
		"jí": "in the manner of", //or "to the side of", "in the direction of (ceremonial/institutional)"
		"jį́ʼ": "up to", //or "as far as"
		//"jí-kʼehgo": "in the manner of",
		"k’ą́ą́h": "against",
		"k’ee": "on account of",
		"k’eh": "according to",
		//"k’eh (-jí)": "in the way(s) of",
		//"k’eh-jí": "in the language of",
		"k’é": "in exchange for",
		"k’i": "over", //or "on", "off"
		"ká": "after", //or "for"
		"káá’": "on top of",
		"kéé’": "behind", //or "following"
		"lááh": "greater than", //or "beyond (numerically)"
		"na": "around",
		"na’": "beside",
		"naa": "around",
		"naashii": "across from", //or "in opposition to"
		"nah": "aside",
		"ná": "encircling", //or "around"
		"nánii": "on the edge of", //or "on the slope of"
		"ne’": "behind",
		"ni": "in, during",
		"niinaa": "because of",
		"niit’aa": "to the barrier of",
		"niiyé": "for the purpose of",
		"ní": "into the surface of (without piercing)",
		"níká": "through",
		"t’ah": "in the hidden space of",
		"t’ááh": "close to",
		"ta": "among",
		"ta’": "between",
		"taa": "among",
		"tah": "among",
		"tis": "over",
		"ts’ąą": "concealed from", //or "out of reach of"
		"ts’ą́ą́’": "away from",
		"tsąąh": "during",
		"tsé": "before",
		"tsi": "the first in",
		"tł’ááh": "beneath",
		"yaa": "under",
		"yah": "under",
		"yę́ędą́ą́’": "back when",
		"yi’": "within", //or "inside of"
		"yaaghah": "around",
		"zánághah": "around"
	]

	//Initializer
	public init() {

	}

	/**
		Tokenize an adverb using Navajo polysynthetic rules

		- Parameters:
			- adverb: Tokenized word object
		- Returns: Modified object with subcomponent array included
	 */
	public func tokenize(adverb: NVWordToken) -> NVWordToken {

		if adverb.pos?.lowercased() != "adv" {
			return adverb
		}

		var token = adverb

		//Check if the Adverb is formed by adding a Postposition suffix to a base
		for suffix in postpositionSuffixList {

			if token.token.hasSuffix(suffix.key) {

				let base = "\(token.token.dropLast(suffix.key.count))"

				//Place postposition at the beginning
				token.components.append(NVWordToken(token: suffix.key, adjustedToken: suffix.key, pos: "Adp",
				translation: suffix.value))

				//Place stem at the end
				//For the moment, we don't know the part-of-speech
				token.components.append(NVWordToken(token: base, adjustedToken: base))

				break
			}

		}

		return token

	}

	/**
		Tokenize a noun using Navajo polysynthetic rules

		- Parameters:
			- noun: Tokenized word object
			- skipPossessive: Flag for whether or not a possessive prefix should be considered in the tokenization
		- Returns: Modified object with subcomponent array included
	 */
	public func tokenize(noun: NVWordToken, skipPossessive: Bool = false) -> NVWordToken {

		//This function only accepts nouns
		if noun.pos?.lowercased().prefix(1) != "n" {
			return noun
		}

		//Copy to variable for further handling
		var token = noun

		//Check for possessive prefix
		if !skipPossessive {

			//Check if the Noun is formed by adding a possessive prefix to a base
			for prefix in possessivePrefixList {

				if token.adjustedToken.hasPrefix(prefix.token) {

					//Possessive prefix
					token.components.append(
						NVWordToken(
							token: prefix.token,
							adjustedToken: prefix.adjustedToken,
							translation: prefix.translation,
							person: prefix.person,
							plurality: prefix.plurality
						)
					)

					//Remove possessive prefix
					let newToken = "\(token.adjustedToken.dropFirst(prefix.adjustedToken.count))"
					var adjustedNewToken = newToken

					//A prefix with accent means the base noun begins with an accent
					if prefix.token != prefix.adjustedToken {
						adjustedNewToken = "á\(newToken)"
					}

					let base = NVWordToken(
						token: newToken,
						adjustedToken: adjustedNewToken,
						pos: "n",
						translation: token.translation
					)

					//Further recurse through the noun then return
					token.components.append(
						self.tokenize(noun: base, skipPossessive: true)
					)

					break
				}

			}

		//Do checks beyond possessive prefixes
		} else {



		}

		return token

	}
}
