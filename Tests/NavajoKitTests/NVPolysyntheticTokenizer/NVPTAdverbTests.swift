//
//  NSPTAdverbTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/15/25.
//

import XCTest
@testable import NavajoKit

final class NSPTAdverbTests: XCTestCase {

	private let tokenizer = NVPolysyntheticTokenizer()

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

    func testAdverbFromEnclitic() throws {

		let adverbList: [NVPTTestCase] = [
			NVPTTestCase(
				input: NVWordToken(
					token: "abinídóó",
					adjustedToken: "abinídóó",
					pos: "Adv",
					components: []
				),
				expected: NVWordToken(
					token: "abinídóó",
					adjustedToken: "abinídóó",
					pos: "Adv",
					components: [
						NVWordToken(
							token: "abiní",
							adjustedToken: "abiní"
						),
						NVWordToken(
							token: "dóó",
							adjustedToken: "dóó",
							translation: "from then"
						),
					]
				)
			),
			NVPTTestCase(
				input: NVWordToken(
					token: "ałtsogóó",
					adjustedToken: "ałtsogóó",
					pos: "Adv",
					components: []
				),
				expected: NVWordToken(
					token: "ałtsogóó",
					adjustedToken: "ałtsogóó",
					pos: "Adv",
					components: [
						NVWordToken(
							token: "ałtso",
							adjustedToken: "ałtso"
						),
						NVWordToken(
							token: "góó",
							adjustedToken: "góó",
							translation: "toward"
						),
					]
				)
			),
		]

		for testCase in adverbList {
			let processed = tokenizer.tokenize(adv: testCase.input)
			let expected = testCase.expected

			XCTAssertEqual(processed.token, expected.token)
			XCTAssertEqual(processed.adjustedToken, expected.adjustedToken)
			XCTAssertEqual(processed.pos, expected.pos)
			XCTAssertEqual(processed.components[0].token, expected.components[0].token)
			XCTAssertEqual(processed.components[0].adjustedToken, expected.components[0].adjustedToken)
			XCTAssertEqual(processed.components[1].token, expected.components[1].token)
			XCTAssertEqual(processed.components[1].adjustedToken, expected.components[1].adjustedToken)
			XCTAssertEqual(processed.components[1].translation, expected.components[1].translation)
		}
    }

}

/*

components: [Navajo_TranslatorTests.NVWordToken(token: "nihi", adjustedToken: "nihi", pos: nil, translation: Optional("our/your"), person: Optional(Navajo_TranslatorTests.NVPerson.firstOrSecond), plurality: Optional(Navajo_TranslatorTests.NVPlurality.dual), transitive: nil, aspect: nil, infinitive: nil, components: []), Navajo_TranslatorTests.NVWordToken(token: "zhiʼ", adjustedToken: "ázhiʼ", pos: Optional("n"), translation: nil, person: nil, plurality: nil, transitive: nil, aspect: nil, infinitive: nil, components: [])])")

components: [Navajo_TranslatorTests.NVWordToken(token: "nihí", adjustedToken: "nihi", pos: nil, translation: Optional("our/your"), person: Optional(Navajo_TranslatorTests.NVPerson.firstOrSecond), plurality: Optional(Navajo_TranslatorTests.NVPlurality.dual), transitive: nil, aspect: nil, infinitive: nil, components: []), Navajo_TranslatorTests.NVWordToken(token: "nihízhiʼ", adjustedToken: "ánihízhiʼ", pos: Optional("n"), translation: nil, person: nil, plurality: nil, transitive: nil, aspect: nil, infinitive: nil, components: [])])

 */
