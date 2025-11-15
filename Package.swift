// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "NavajoKit",
	platforms: [
		.iOS(.v12),
		.macOS(.v10_14)
	],
	products: [
		.library(
			name: "NavajoKit",
			targets: ["NavajoKit"]
		),
	],
	dependencies: [],
	targets: [
		.target(
			name: "NavajoKit",
			dependencies: [],
			resources: [
				.copy("Resources/NVCompoundWords.csv"),
				.copy("Resources/NVSingleWords.csv"),
				.process("Resources/NavajoTagger.mlmodel")
			]
		),
		.testTarget(
			name: "NavajoKitTests",
			dependencies: ["NavajoKit"],
			resources: []
		),
	]
)
