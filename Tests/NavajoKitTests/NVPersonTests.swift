//
//  NVPersonTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/15/25.
//

import XCTest
@testable import NavajoKit

final class NVPersonTests: XCTestCase {

	private struct TestObj: Codable {
		let person: NVPerson
	}

	private struct TestCase {
		let input: String?
		let expected: NVPerson
	}

	private let testCases: [TestCase] = [
		TestCase(input: "first", expected: .first),
		TestCase(input: "1", expected: .first),
		TestCase(input: "1st", expected: .first),
		TestCase(input: "second", expected: .second),
		TestCase(input: "2", expected: .second),
		TestCase(input: "2nd", expected: .second),
		TestCase(input: "third", expected: .third),
		TestCase(input: "3", expected: .third),
		TestCase(input: "3rd", expected: .third),
		TestCase(input: "fourth", expected: .fourth),
		TestCase(input: "4", expected: .fourth),
		TestCase(input: "4th", expected: .fourth),
		TestCase(input: "spatial", expected: .spatial),
		TestCase(input: "spat", expected: .spatial),
		TestCase(input: "sp", expected: .spatial),
		TestCase(input: "reciprocal", expected: .reciprocal),
		TestCase(input: "recip", expected: .reciprocal),
		TestCase(input: "reflexive", expected: .reflexive),
		TestCase(input: "reflex", expected: .reflexive),
		TestCase(input: "refl", expected: .reflexive),
		TestCase(input: "firstorsecond", expected: .firstOrSecond),
		TestCase(input: "12", expected: .firstOrSecond),
		TestCase(input: "1st/2nd", expected: .firstOrSecond),
		TestCase(input: "indefinite", expected: .indefinite),
		TestCase(input: "indef", expected: .indefinite),
		TestCase(input: "foo", expected: .unspecified),
		TestCase(input: "", expected: .unspecified),
		TestCase(input: nil, expected: .unspecified),
	]

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

	func testStringInit() throws {

		for testCase in testCases {
			let person = NVPerson(rawValue: testCase.input)
			XCTAssertEqual(person, testCase.expected)

			let personUpper = NVPerson(rawValue: testCase.input?.uppercased())
			XCTAssertEqual(personUpper, testCase.expected)

			let personCapitalized = NVPerson(rawValue: testCase.input?.capitalized)
			XCTAssertEqual(personCapitalized, testCase.expected)
		}

    }

	func testDecoderInit() throws {

		for testCase in testCases {

			let input  = testCase.input == nil ? "null" : "\"\(testCase.input!)\""

			let json = "{\"person\":\(input)}".data(using: .utf8)!

			let object = try JSONDecoder().decode(TestObj.self, from: json)

			XCTAssertEqual(object.person, testCase.expected)
		}

    }
}
