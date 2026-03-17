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
				.copy("Resources/NVSingleWords.csv"),
				.copy("Resources/NVCompoundWords.csv"),
				.copy("Resources/NVClauses.csv"),
				.copy("Resources/NVPassages.csv"),
				.copy("Resources/training_data.json"),
				.copy("Resources/train_transformer.py"),
				.copy("Resources/vocab.json"),
				.process("Resources/NavajoTagger.mlmodel"),
				.process("Resources/NavajoEncoder.mlpackage"),
				.process("Resources/NavajoDecoder.mlpackage")
			],
		),
		.testTarget(
			name: "NavajoKitTests",
			dependencies: ["NavajoKit"],
			resources: []
		),
	]
)
