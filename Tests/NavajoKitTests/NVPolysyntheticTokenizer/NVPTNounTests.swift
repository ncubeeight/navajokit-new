//
//  NVPTNounTests.swift
//
//  Created by Daniel Gump on 7/23/25.
//

import XCTest
@testable import NavajoKit

final class NVPTNounTests: XCTestCase {

	private let tokenizer = NVPolysyntheticTokenizer()

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

	func testPossessiveNoun() throws {

		let nounList: [NVPTTestCase] = [
			NVPTTestCase(
				input: NVWordToken(
					token: "shimá",
					adjustedToken: "shimá",
					pos: "n",
					components: []
				),
				expected: NVWordToken(
					token: "shimá",
					adjustedToken: "shimá",
					pos: "n",
					components: [
						NVWordToken(
							token: "shi",
							adjustedToken: "shi",
							translation: "my",
							person: .first,
							plurality: .singular
						),
						NVWordToken(
							token: "má",
							adjustedToken: "amá",
							pos: "n"
						),
					]
				)
			),
			NVPTTestCase(
				input: NVWordToken(
					token: "nihízhiʼ",
					adjustedToken: "nihízhiʼ",
					pos: "n",
					components: []
				),
				expected: NVWordToken(
					token: "nihízhiʼ",
					adjustedToken: "nihízhiʼ",
					pos: "n",
					components: [
						NVWordToken(
							token: "nihí",
							adjustedToken: "nihi",
							translation: "our/your",
							person: .firstOrSecond,
							plurality: .dual
						),
						NVWordToken(
							token: "zhiʼ",
							adjustedToken: "ázhiʼ",
							pos: "n"
						),
					]
				)
			),
		]

		for testCase in nounList {
			XCTAssertEqual(tokenizer.tokenize(noun: testCase.input).token, testCase.expected.token)
			XCTAssertEqual(tokenizer.tokenize(noun: testCase.input).adjustedToken, testCase.expected.adjustedToken)
			XCTAssertEqual(tokenizer.tokenize(noun: testCase.input).pos, testCase.expected.pos)
			//TODO: XCTAssertEqual(tokenizer.tokenize(noun: testCase.input), testCase.expected)
			//TODO: XCTAssertEqual(tokenizer.tokenize(noun: testCase.input).components, testCase.expected.components)
		}
    }

}

/*

components: [Navajo_TranslatorTests.NVWordToken(token: "nihi", adjustedToken: "nihi", pos: nil, translation: Optional("our/your"), person: Optional(Navajo_TranslatorTests.NVPerson.firstOrSecond), plurality: Optional(Navajo_TranslatorTests.NVPlurality.dual), transitive: nil, aspect: nil, infinitive: nil, components: []), Navajo_TranslatorTests.NVWordToken(token: "zhiʼ", adjustedToken: "ázhiʼ", pos: Optional("n"), translation: nil, person: nil, plurality: nil, transitive: nil, aspect: nil, infinitive: nil, components: [])])")

components: [Navajo_TranslatorTests.NVWordToken(token: "nihí", adjustedToken: "nihi", pos: nil, translation: Optional("our/your"), person: Optional(Navajo_TranslatorTests.NVPerson.firstOrSecond), plurality: Optional(Navajo_TranslatorTests.NVPlurality.dual), transitive: nil, aspect: nil, infinitive: nil, components: []), Navajo_TranslatorTests.NVWordToken(token: "nihízhiʼ", adjustedToken: "ánihízhiʼ", pos: Optional("n"), translation: nil, person: nil, plurality: nil, transitive: nil, aspect: nil, infinitive: nil, components: [])])

 */
