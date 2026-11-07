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
		// Optional sentence translation (NVTranslator.translate(_:tokenizer:)).
		// Kept separate because its transformer models are ~33 MB; apps that
		// only need word lookups, tagging and pronunciation can skip it.
		.library(
			name: "NavajoKitTransformer",
			targets: ["NavajoKitTransformer"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
	],
	targets: [
		.target(
			name: "NavajoKit",
			dependencies: [],
			exclude: [
				// Training data and scripts stay in the repo but aren't
				// shipped: nothing loads them at run time.
				"Resources/training_data/NVClauses.csv",
				"Resources/training_data/NVPassages.csv",
				"Resources/training_data/bible.json",
				"Resources/training_data/compound words.json",
				"Resources/training_data/hymns.json",
				"Resources/training_data/narratives.json",
				"Resources/training_data/phrases.json",
				"Resources/training_data/sentences.json",
				"Resources/train_transformer.py",
				"Resources/setup_and_run.sh",
				"Resources/tokenizer.vocab"
			],
			resources: [
				.copy("Resources/training_data/NVSingleWords.csv"),
				.copy("Resources/training_data/NVCompoundWords.csv"),
				.copy("Resources/vocab.json"),
				.process("Resources/NavajoTagger.mlmodel")
			],
		),
		.target(
			name: "NavajoKitTransformer",
			dependencies: ["NavajoKit"],
			resources: [
				.process("Resources/NavajoEncoder.mlpackage"),
				.process("Resources/NavajoDecoder.mlpackage")
			],
		),
		.testTarget(
			name: "NavajoKitTransformerTests",
			dependencies: ["NavajoKitTransformer"]
		),
		.testTarget(
			name: "NavajoKitTests",
			dependencies: ["NavajoKit"],
			resources: []
		),
	]
)
