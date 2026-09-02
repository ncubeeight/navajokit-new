// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "NavajoKit",
	platforms: [
		.iOS(.v15),
		.macOS(.v12)
	],
	products: [
		.library(
			name: "NavajoKit",
			targets: ["NavajoKit"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
	],
	targets: [
		.target(
			name: "NavajoKit",
			dependencies: [],
			resources: [
				.copy("Resources/training_data/NVSingleWords.csv"),
				.copy("Resources/training_data/NVCompoundWords.csv"),
				//.copy("Resources/training_data/NVClauses.csv"),
				//.copy("Resources/training_data/NVPassages.csv"),
				//.copy("Resources/training_data/bible.json"),
				//.copy("Resources/training_data/compound_words.json"),
				//.copy("Resources/training_data/phrases.json"),
				//.copy("Resources/training_data/narratives.json"),
				//.copy("Resources/training_data/sentences.json"),
				//.copy("Resources/training_data/words.json"),
				//.copy("Resources/train_transformer.py"),
				.copy("Resources/vocab.json"),
				.process("Resources/NavajoTagger.mlmodel"),
				.process("Resources/EnglishDecoder.mlpackage"),
				.process("Resources/EnglishEncoder.mlpackage"),
				.process("Resources/NavajoDecoder.mlpackage"),
				.process("Resources/NavajoEncoder.mlpackage"),
			],
		),
		.testTarget(
			name: "NavajoKitTests",
			dependencies: ["NavajoKit"],
			resources: []
		),
	]
)
