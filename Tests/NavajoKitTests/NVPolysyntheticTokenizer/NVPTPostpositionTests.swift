//
//  NVPTPostpositionTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/15/25.
//

import XCTest
@testable import NavajoKit

final class NVPTPostpositionTests: XCTestCase {

	private let tokenizer = NVPolysyntheticTokenizer()

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

	func testPostpositionObject() throws {

		let postpositionList: [NVPTTestCase] = [
			NVPTTestCase(
				input: NVWordToken(
					token: "shił",
					adjustedToken: "shił",
					pos: "postp",
					components: []
				),
				expected: NVWordToken(
					token: "shił",
					adjustedToken: "shił",
					pos: "Postp",
					components: [
						NVWordToken(
							token: "shi",
							adjustedToken: "shi",
							pos: "ProObj",
							translation: "me",
							person: .first,
							plurality: .singular
						),
						NVWordToken(
							token: "ł",
							adjustedToken: "ił",
							pos: "Postp",
							translation: "with"
						),
					]
				)
			),
			NVPTTestCase(
				input: NVWordToken(
					token: "yichʼą́ą́h",
					adjustedToken: "yichʼą́ą́h",
					pos: "Postp",
					components: []
				),
				expected: NVWordToken(
					token: "yichʼą́ą́h",
					adjustedToken: "yichʼą́ą́h",
					pos: "Postp",
					components: [
						NVWordToken(
							token: "yi",
							adjustedToken: "yi",
							pos: "ProObj",
							translation: "him/her/it/them",
							person: .third,
							plurality: .any
						),
						NVWordToken(
							token: "chʼą́ą́h",
							adjustedToken: "chʼą́ą́h",
							pos: "Postp",
							translation: "blocking",
						),
					]
				)
			),
		]

		for testCase in postpositionList {
			let processed = tokenizer.tokenize(postp: testCase.input)
			let expected = testCase.expected

			XCTAssertEqual(processed.token, expected.token)
			XCTAssertEqual(processed.adjustedToken, expected.adjustedToken)
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
