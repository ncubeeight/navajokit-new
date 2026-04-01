//
//  NVTokenizerTests.swift
//  NavajoKit
//
//  Created by Daniel Gump on 3/26/26.
//

import XCTest
@testable import NavajoKit

final class NVTokenizerTests: XCTestCase {

	//This tests for a fix to a specific issue in which certain Unicode characters with multiple diacritic marks would merge/
	func testCleanDecomposedStringWithCanonicalMapping() async {

		let tokenizer = NVTokenizer()

		let options: NVTokenizer.Options = [
			.caseInsensitive,
			.stripDigits,
			.tokenizePunctuation,
			.stripLeadingGlottalStops,
			.stripDigits
		]

		let tokens1 = await tokenizer.tokenize("łitsooí", unit: .word)
		XCTAssertEqual("łitsooí", tokens1.0)
		XCTAssertNotEqual("łitsoǫ́", tokens1.0)

		let tokens2 = await tokenizer.tokenize("łitsooí", unit: .word, options: options)
		XCTAssertEqual("łitsooí", tokens2.0)
		XCTAssertNotEqual("łitsoǫ́", tokens2.0)
	}

}
