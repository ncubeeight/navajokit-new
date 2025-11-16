//
//  NVPluralityTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/15/25.
//

import XCTest
@testable import NavajoKit

final class NVPluralityTests: XCTestCase {

	private struct TestObj: Codable {
		let plurality: NVPlurality
	}

	private struct TestCase {
		let input: String?
		let expected: NVPlurality
	}

	private let testCases: [TestCase] = [
		TestCase(input: "singular", expected: .singular),
		TestCase(input: "1", expected: .singular),
		TestCase(input: "s", expected: .singular),
		TestCase(input: "dual", expected: .dual),
		TestCase(input: "duoplural", expected: .dual),
		TestCase(input: "2", expected: .dual),
		TestCase(input: "d", expected: .dual),
		TestCase(input: "plural", expected: .plural),
		TestCase(input: "distributive", expected: .plural),
		TestCase(input: "distributiveplural", expected: .plural),
		TestCase(input: "3", expected: .plural),
		TestCase(input: "3+", expected: .plural),
		TestCase(input: "p", expected: .plural),
		TestCase(input: "singularordual", expected: .singularOrDual),
		TestCase(input: "singularorduoplural", expected: .singularOrDual),
		TestCase(input: "12", expected: .singularOrDual),
		TestCase(input: "sd", expected: .singularOrDual),
		TestCase(input: "dualorplural", expected: .dualOrPlural),
		TestCase(input: "23", expected: .dualOrPlural),
		TestCase(input: "dp", expected: .dualOrPlural),
		TestCase(input: "foo", expected: .any),
		TestCase(input: "", expected: .any),
		TestCase(input: nil, expected: .any),
	]

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

	func testStringInit() throws {

		for testCase in testCases {
			let plurality = NVPlurality(rawValue: testCase.input)
			XCTAssertEqual(plurality, testCase.expected)

			let pluralityUpper = NVPlurality(rawValue: testCase.input?.uppercased())
			XCTAssertEqual(pluralityUpper, testCase.expected)

			let pluralityCapitalized = NVPlurality(rawValue: testCase.input?.capitalized)
			XCTAssertEqual(pluralityCapitalized, testCase.expected)
		}

    }

	func testDecoderInit() throws {

		for testCase in testCases {

			let input  = testCase.input == nil ? "null" : "\"\(testCase.input!)\""

			let json = "{\"plurality\":\(input)}".data(using: .utf8)!

			let object = try JSONDecoder().decode(TestObj.self, from: json)

			XCTAssertEqual(object.plurality, testCase.expected)
		}

    }
}
