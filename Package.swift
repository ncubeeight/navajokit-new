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
				.process("Resources/NavajoTagger.mlmodel")
			],
		),
		.testTarget(
			name: "NavajoKitTests",
			dependencies: ["NavajoKit"],
			resources: []
		),
	]
)
