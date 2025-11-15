//
//  NVAspectTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/15/25.
//

import XCTest
@testable import NavajoKit

final class NVAspectTests: XCTestCase {

	private struct TestObj: Codable {
		let aspect: NVAspect
	}

	private struct TestCase {
		let input: String?
		let expected: NVAspect
	}

	private let testCases: [TestCase] = [
		TestCase(input: "perfective", expected: .perfective),
		TestCase(input: "perfect", expected: .perfective),
		TestCase(input: "past", expected: .perfective),
		TestCase(input: "perf", expected: .perfective),
		TestCase(input: "imperfective", expected: .imperfective),
		TestCase(input: "imperfect", expected: .imperfective),
		TestCase(input: "present", expected: .imperfective),
		TestCase(input: "impf", expected: .imperfective),
		TestCase(input: "future", expected: .future),
		TestCase(input: "fut", expected: .future),
		TestCase(input: "iterative", expected: .iterative),
		TestCase(input: "repetitive", expected: .iterative),
		TestCase(input: "iter", expected: .iterative),
		TestCase(input: "rep", expected: .iterative),
		TestCase(input: "optative", expected: .optative),
		TestCase(input: "opt", expected: .optative),
		TestCase(input: "progressive", expected: .progressive),
		TestCase(input: "prog", expected: .progressive),
		TestCase(input: "unspecified", expected: .unspecified),
		TestCase(input: "unspec", expected: .unspecified),
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
			let aspect = NVAspect(rawValue: testCase.input)
			XCTAssertEqual(aspect, testCase.expected)

			let aspectUpper = NVAspect(rawValue: testCase.input?.uppercased())
			XCTAssertEqual(aspectUpper, testCase.expected)

			let aspectCapitalized = NVAspect(rawValue: testCase.input?.capitalized)
			XCTAssertEqual(aspectCapitalized, testCase.expected)
		}

    }

	func testDecoderInit() throws {

		for testCase in testCases {

			let input  = testCase.input == nil ? "null" : "\"\(testCase.input!)\""

			let json = "{\"aspect\":\(input)}".data(using: .utf8)!

			let object = try JSONDecoder().decode(TestObj.self, from: json)

			XCTAssertEqual(object.aspect, testCase.expected)
		}

    }
}
