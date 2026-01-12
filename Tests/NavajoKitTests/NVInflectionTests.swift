//
//  NVInflectionTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 1/1/26.
//

import XCTest
@testable import NavajoKit

final class NVInflectionTests: XCTestCase {

	private struct TestCase {
		let input: NVInflection
		let expected: String
	}

	private let testCases: [TestCase] = [
		TestCase(input: NVInflection(person: .first, plural: .singular), expected: "1S"),
		TestCase(input: NVInflection(person: .second, plural: .singularOrDual), expected: "2SD"),
		TestCase(input: NVInflection(person: .third, plural: .dual), expected: "3D"),
		TestCase(input: NVInflection(person: .fourth, plural: .dualOrPlural), expected: "4DP"),
		TestCase(input: NVInflection(person: .fourthO, plural: .plural), expected: "3(O)P"),
		TestCase(input: NVInflection(person: .fourthA, plural: .singular), expected: "3(A)S"),
		TestCase(input: NVInflection(person: .fourthI, plural: .singularOrDual), expected: "3(I)SD"),
		TestCase(input: NVInflection(person: .indefinite, plural: .dual), expected: "3(I)D"),
		TestCase(input: NVInflection(person: .spatial, plural: .dualOrPlural), expected: "SpatDP"),
		TestCase(input: NVInflection(person: .reciprocal, plural: .plural), expected: "RecipP"),
		TestCase(input: NVInflection(person: .reflexive, plural: .singular), expected: "ReflS"),
		TestCase(input: NVInflection(person: .firstOrSecond, plural: .dual), expected: "1/2D"),
		TestCase(input: NVInflection(person: .unspecified, plural: .singularOrDual), expected: ""),
		TestCase(input: NVInflection(person: nil, plural: .dual), expected: ""),
		TestCase(input: NVInflection(person: nil, plural: nil), expected: ""),
		TestCase(input: NVInflection(person: .third, plural: nil), expected: "3"),
	]

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

	func testInflections() throws {

		for testCase in testCases {
			XCTAssertEqual(testCase.input.getInflection(), testCase.expected)

		}

    }
}
