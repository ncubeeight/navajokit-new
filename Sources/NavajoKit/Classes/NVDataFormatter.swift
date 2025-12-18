//
//  NVDataFormatter.swift
//  NavajoKit
//
//  Created by Daniel Gump on 12/17/25.
//

import Foundation

///Converts various data structures into JSON compatibilty with CoreML training
public class NVDataFormatter {

	///Singleton
	@MainActor
	public static let shared = NVDataFormatter()

	public struct Options: OptionSet, Sendable {
		public let rawValue: Int

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		///Strip additionals references to the columns "tokens" and "labels" (case-insensitive) within the data body
		public static let stripMergedTableReferences = Options(rawValue: 1 << 0)
	}

	public var delegate: NVDataFormatterDelegate?

	public init(delegate: NVDataFormatterDelegate? = nil) {
		self.delegate = delegate
	}

	deinit {
		self.delegate = nil
	}

	///Tab-separated values string to JSON string
	///> Important: This function strips out all columns except for those named "tokens" and "labels" (case-insensitive).
	public func convertTSVtoJSON(_ tsv: String, options: NVDataFormatter.Options = []) async -> String {

		let rows = tsv.components(separatedBy: .newlines)

		if rows.isEmpty || rows.count == 0 {
			await delegate?.conversionPercent(current: 100.0)
			return ""
		}

		var jsonArray: [[String: Any]] = []

		// Process header row
		let headers = splitTSV(row: rows.first ?? "")
		let tokensIndex = headers.firstIndex { $0.lowercased() == "tokens" }
		let labelsIndex = headers.firstIndex { $0.lowercased() == "labels" }
        
		//Process data rows
		for row in rows[1...] where !row.isEmpty {

			let values = splitTSV(row: row)
			var rowDict: [String: [String]] = [:]

			await delegate?.conversionPercent(current: 100.0 * (Double(row) ?? 0.0) / Double(rows.count))

			if let tokensIndex = tokensIndex,
				tokensIndex < values.count {

				rowDict["tokens"] = splitCSV(record: values[tokensIndex].lowercased())
			}

			if let labelsIndex = labelsIndex,
				labelsIndex < values.count {

				rowDict["labels"] = splitCSV(record: values[labelsIndex])

			}

			//Strip out additional table header rows
			if options.contains(.stripMergedTableReferences) {

				if rowDict["tokens"]?.first?.lowercased() == "tokens",
					rowDict["labels"]?.first?.lowercased() == "labels" {

					continue
				}
			}

			jsonArray.append(rowDict)

		}

		do {
			let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.sortedKeys, .prettyPrinted])
		  return String(data: jsonData, encoding: .utf8) ?? "Error converting to JSON"
		} catch {
		  return "Error: \(error.localizedDescription)"
		}
	}

	//Split TSV record into individual fields
	private func splitTSV(row: String) -> [String] {

		return row
			.split(separator: "\t")
			.map({
				return String($0)
					.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
			})

	}

	//Split TSV field into individual subfields
	private func splitCSV(record: String) -> [String] {

		return record
			.replacingOccurrences(of: "\"\",\"\"", with: "\n")
			.replacingOccurrences(of: "\"\"", with: "\"")
			.split(separator: ",")
			.map({
				return String($0).replacingOccurrences(of: "\n", with: ",").trimmingCharacters(in: .whitespaces)
			})

	}

}

public protocol NVDataFormatterDelegate: AnyObject {

	///Report back the conversion percent
	func conversionPercent(current: Double) async

}
