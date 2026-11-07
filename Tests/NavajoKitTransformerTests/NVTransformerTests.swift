//
//  NVTransformerTests.swift
//  NavajoKitTransformer
//

import XCTest
import NavajoKit
@testable import NavajoKitTransformer

final class NVTransformerTests: XCTestCase {

	@MainActor
	func testSentenceTranslationLoadsModels() {
		let output = NVTranslator().translate("Yáʼátʼééh", tokenizer: NVTokenizer())
		XCTAssertFalse(output.isEmpty)
	}
}
