//
//  NVDataFormatterTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 1/5/26.
//

import XCTest
@testable import NavajoKit

final class NVDataFormatterTests: XCTestCase {

	//CSV/TSV record to string array
	private struct TestDecodeCase {
		let input: String
		let expected: [String]
	}

	//String array to CSV/TSV record
	private struct TestEncodeCase {
		let input: [String]
		let expected: String
	}

	private let csvDecodeTestCases: [TestDecodeCase] = [
		TestDecodeCase(input: "foo", expected: ["foo"]),
		TestDecodeCase(input: "foo,bar", expected: ["foo", "bar"]),
		TestDecodeCase(input: ",", expected: ["", ""]),
		TestDecodeCase(input: "", expected: [""]),
		TestDecodeCase(input: "foo,\"bar\"", expected: ["foo", "bar"]),
		TestDecodeCase(input: "\"foo,bar\"", expected: ["foo,bar"]),
		TestDecodeCase(input: "\"foo,bar\",blar", expected: ["foo,bar", "blar"]),
		TestDecodeCase(input: "\"foo,bar\",blar,\"\"", expected: ["foo,bar", "blar",""]),
		TestDecodeCase(input: "\"foo,bar\",blar,\"\"\"", expected: ["foo,bar", "blar", "\""]),
		TestDecodeCase(input: "\"foo\nbar\"", expected: ["foo\nbar"]),
		TestDecodeCase(input: "\"foo\rbar\"", expected: ["foo\rbar"]),
		TestDecodeCase(input: "\"foo\"\"\"\"bar\"", expected: ["foo\"\"bar"]),
		TestDecodeCase(input: ",,,", expected: ["", "", "", ""]),
		//TestDecodeCase(input: " foo , \" bar \" ", expected: [" foo ", " bar  "]),
		TestDecodeCase(input: "\"\"\"\"\"\"", expected: ["\"\""]),
		TestDecodeCase(input: "foo\"bar", expected: ["foobar"]),
		TestDecodeCase(input: "\"foo\"bar\"", expected: ["foobar"]),
	]

	private let tsvDecodeTestCases: [TestDecodeCase] = [
		TestDecodeCase(input: "foo", expected: ["foo"]),
		TestDecodeCase(input: "foo\tbar", expected: ["foo", "bar"]),
		TestDecodeCase(input: "\t", expected: ["", ""]),
		TestDecodeCase(input: "", expected: [""]),
		TestDecodeCase(input: "foo\t\"bar\"", expected: ["foo", "bar"]),
		TestDecodeCase(input: "\"foo\tbar\"", expected: ["foo\tbar"]),
		TestDecodeCase(input: "\"foo\tbar\"\tblar", expected: ["foo\tbar", "blar"]),
		TestDecodeCase(input: "\"foo\tbar\"\tblar\t\"\"", expected: ["foo\tbar", "blar",""]),
		TestDecodeCase(input: "\"foo\tbar\"\tblar\t\"\"\"", expected: ["foo\tbar", "blar", "\""]),
		TestDecodeCase(input: "\"foo\tbar\tblar\"", expected: ["foo\tbar\tblar"]),
		TestDecodeCase(input: "\"foo\nbar\"\t\"baz\rqux\"", expected: ["foo\nbar", "baz\rqux"]),
		TestDecodeCase(input: "\t\t\t", expected: ["", "", "", ""]),
		//TestDecodeCase(input: " foo \t \" bar \" \t", expected: [" foo ", " bar  ", ""]),
		TestDecodeCase(input: "\"\"\"\"\"\"\t\"\"", expected: ["\"\"", ""]),
		//TestDecodeCase(input: "foo\"bar\tbaz", expected: ["foobar", "baz"]),
	]

	private let csvEncodeTestCases: [TestEncodeCase] = [
		TestEncodeCase(input: ["foo"], expected: "foo"),
		TestEncodeCase(input: ["foo", "bar"], expected: "foo,bar"),
		TestEncodeCase(input: ["", ""], expected: ","),
		TestEncodeCase(input: [""], expected: ""),
		TestEncodeCase(input: ["foo", "\"bar\""], expected: "foo,\"\"\"bar\"\"\""),
		TestEncodeCase(input: ["foo,bar"], expected: "\"foo,bar\""),
		TestEncodeCase(input: ["foo,bar", "blar"], expected: "\"foo,bar\",blar"),
		TestEncodeCase(input: ["foo,bar", "blar", ""], expected: "\"foo,bar\",blar,"),
		TestEncodeCase(input: ["foo,bar", "blar", "\""], expected: "\"foo,bar\",blar,\"\"\"\""),
		TestEncodeCase(input: ["foo\nbar"], expected: "\"foo\nbar\""),
		TestEncodeCase(input: ["foo\rbar", "baz"], expected: "\"foo\rbar\",baz"),
		TestEncodeCase(input: ["\"\"", "bar"], expected: "\"\"\"\"\"\",bar"),
		TestEncodeCase(input: ["", "", "", ""], expected: ",,,"),
		TestEncodeCase(input: [" foo ", " bar "], expected: " foo , bar "),
		TestEncodeCase(input: ["\"foo\"", "bar"], expected: "\"\"\"foo\"\"\",bar"),
		TestEncodeCase(input: ["foo\"bar\"baz"], expected: "\"foo\"\"bar\"\"baz\""),
	]

	private let tsvEncodeTestCases: [TestEncodeCase] = [
		TestEncodeCase(input: ["foo"], expected: "foo"),
		TestEncodeCase(input: ["foo", "bar"], expected: "foo\tbar"),
		TestEncodeCase(input: ["", ""], expected: "\t"),
		TestEncodeCase(input: [""], expected: ""),
		TestEncodeCase(input: ["foo", "\"bar\""], expected: "foo\t\"\"\"bar\"\"\""),
		TestEncodeCase(input: ["foo\tbar"], expected: "\"foo\tbar\""),
		TestEncodeCase(input: ["foo\tbar", "blar"], expected: "\"foo\tbar\"\tblar"),
		TestEncodeCase(input: ["foo\tbar", "blar", ""], expected: "\"foo\tbar\"\tblar\t"),
		TestEncodeCase(input: ["foo\tbar", "blar", "\""], expected: "\"foo\tbar\"\tblar\t\"\"\"\""),
		TestEncodeCase(input: ["foo\tbar"], expected: "\"foo\tbar\""),
		TestEncodeCase(input: ["foo\nbar\tbaz\rqux"], expected: "\"foo\nbar\tbaz\rqux\""),
		//TestEncodeCase(input: ["\"\"\"", "bar"], expected: "\"\"\"\"\"\"\"\",bar"),
		TestEncodeCase(input: ["", "", "", ""], expected: "\t\t\t"),
		TestEncodeCase(input: [" foo ", "\tbar\t"], expected: " foo \t\"\tbar\t\""),
		TestEncodeCase(input: ["\"foo\t\""], expected: "\"\"\"foo\t\"\"\""),
	]

 	func testDecodeEncodeCases() throws {

		let df = NVDataFormatter()

		for testCase in csvDecodeTestCases {

			let record = df.splitRecord(fromCsv: testCase.input)
			XCTAssertEqual(record, testCase.expected, testCase.input)

		}

		for testCase in tsvDecodeTestCases {

			let record = df.splitRecord(fromTsv: testCase.input)
			XCTAssertEqual(record, testCase.expected, testCase.input)

		}

		//Run the previous tests in reverse for encoding
		for testCase in csvEncodeTestCases {

			let record = df.joinArray(toCsv: testCase.input)
			XCTAssertEqual(record, testCase.expected, testCase.expected)

		}

		for testCase in tsvEncodeTestCases {

			let record = df.joinArray(toTsv: testCase.input)
			XCTAssertEqual(record, testCase.expected, testCase.expected)

		}
	}

}
