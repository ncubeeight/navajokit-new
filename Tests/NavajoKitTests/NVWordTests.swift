//
//  NVWordTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 1/1/26.
//

import XCTest
@testable import NavajoKit

final class NVWordTests: XCTestCase {

	private struct TestCase {
		let input: NVWord
		let expected: String
	}

	private let testCases: [TestCase] = [
		TestCase(input: NVWord(navajo: "", english: "", partOfSpeech: "", validated: true, subject: NVInflection(person: nil, plural: nil), object: NVInflection(person: nil, plural: nil)), expected: ""),
		TestCase(input: NVWord(navajo: "", english: "", partOfSpeech: "", validated: true, subject: NVInflection(person: .first, plural: .singular), object: NVInflection(person: nil, plural: nil)), expected: "1S"),
		TestCase(input: NVWord(navajo: "", english: "", partOfSpeech: "", validated: true, subject: NVInflection(person: .second, plural: .dual), object: NVInflection(person: nil, plural: nil)), expected: "2D"),
		TestCase(input: NVWord(navajo: "", english: "", partOfSpeech: "", validated: true, subject: NVInflection(person: .third, plural: .singularOrDual), object: NVInflection(person: .third, plural: .plural)), expected: "3SD -> 3P"),
		TestCase(input: NVWord(navajo: "", english: "", partOfSpeech: "", validated: true, subject: NVInflection(person: nil, plural: nil), object: NVInflection(person: .reciprocal, plural: .plural)), expected: "-> RecipP"),
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
