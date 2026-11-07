//
//  NVTranslatorWordTests.swift
//  NavajoKit
//
//  Word lookups must keep working from the core library alone, without
//  the optional NavajoKitTransformer models.
//

import XCTest
@testable import NavajoKit

final class NVTranslatorWordTests: XCTestCase {

	@MainActor
	func testWordLookupWithoutTransformer() async {
		let translator = NVTranslator()
		XCTAssertFalse(translator.lexiconList.isEmpty)

		let tagged = await NVTagger().tag(["dibé"])
		let english = translator.translate(words: tagged).first?.translation?.english ?? ""
		XCTAssertTrue(english.contains("sheep"), "got \(english)")
	}
}
