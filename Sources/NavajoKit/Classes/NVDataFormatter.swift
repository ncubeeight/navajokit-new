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

	///Custom settings for the conversions
	public struct Options: OptionSet, Sendable {
		public let rawValue: Int

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		///Strip additionals references to the columns "tokens" and "labels" (case-insensitive) within the data body
		public static let stripMergedTableReferences = Options(rawValue: 1 << 0)
		///Export the JSON  in pretty print format
		public static let prettyPrintedJSON = Options(rawValue: 1 << 1)
	}

	///Report on conversion status
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
		let headers = splitRecord(fromTsv: rows.first ?? "")
		let tokensIndex = headers.firstIndex { $0.lowercased() == "tokens" }
		let labelsIndex = headers.firstIndex { $0.lowercased() == "labels" }
        
		//Process data rows
		for row in rows[1...] where !row.isEmpty {

			let values = splitRecord(fromTsv: row)
			var rowDict: [String: [String]] = [:]

			await delegate?.conversionPercent(current: 100.0 * (Double(row) ?? 0.0) / Double(rows.count))

			if let tokensIndex = tokensIndex,
				tokensIndex < values.count {

				rowDict["tokens"] = splitRecord(fromCsv: values[tokensIndex].lowercased())
			}

			if let labelsIndex = labelsIndex,
				labelsIndex < values.count {

				rowDict["labels"] = splitRecord(fromCsv: values[labelsIndex])

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

			var opt = JSONSerialization.WritingOptions()
			opt.insert(.sortedKeys)
			if options.contains(.prettyPrintedJSON) {
				opt.insert( .prettyPrinted)
			}

			let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: opt)
		  return String(data: jsonData, encoding: .utf8) ?? "Error converting to JSON"
		} catch {
		  return "Error: \(error.localizedDescription)"
		}
	}

	//Split CSV record into individual fields
	public func splitRecord(fromCsv: String) -> [String] {

		var fields: [String] = []
		var currentField: String = ""
		var isInsideQuotes: Bool = false

		let chars = Array(fromCsv)
		var index = 0

		while index < chars.count {
			let char = chars[index]

			switch char {

				case "\"":

					if isInsideQuotes {

						//Check for double quotes
						if index + 1 < chars.count && chars[index + 1] == "\"" {

							currentField.append("\"")
							index += 1 //skip next quote

						//End of quotes
						} else {

							isInsideQuotes = false

						}

					//Start of quoted field
					} else {

						isInsideQuotes = true

					}

				case ",":

					if isInsideQuotes {

						currentField.append(char)

					} else {

						fields.append(currentField)
						currentField = ""

					}

				default:

					currentField.append(char)
			}

			index += 1

		}

		//Append last field
		fields.append(currentField)

		return fields
	}

	//Split TSV record into individual fields
	public func splitRecord(fromTsv: String) -> [String] {

		var fields: [String] = []
		var currentField: String = ""
		var isInsideQuotes: Bool = false

		let chars = Array(fromTsv)
		var index = 0

		while index < chars.count {
			let char = chars[index]

			switch char {

				case "\"":

					if isInsideQuotes {

						//Check for double quotes
						if index + 1 < chars.count && chars[index + 1] == "\"" {

							currentField.append("\"")
							index += 1 //skip next quote

						//End of quotes
						} else {

							isInsideQuotes = false

						}

					//Start of quoted field
					} else {

						isInsideQuotes = true

					}

				case "\t":

					if isInsideQuotes {

						currentField.append(char)

					} else {

						fields.append(currentField)
						currentField = ""

					}

				default:

					currentField.append(char)
			}

			index += 1

		}

		//Append last field
		fields.append(currentField)

		return fields

	}

	//Join CSV record from individual fields
	public func joinArray(toCsv: [String]) -> String {

		let record = toCsv.map({

			if $0.contains(",") || $0.contains("\n") || $0.contains("\r") || $0.contains("\"") {

				let escaped = $0.replacingOccurrences(of: "\"", with: "\"\"")
				return "\"\(escaped)\""

			} else {
				return $0
			}
		}).joined(separator: ",")

		return record
	}

	//Join TSV record from individual fields
	public func joinArray(toTsv: [String]) -> String {

		let record = toTsv.map({

			if $0.contains("\n") || $0.contains("\r") || $0.contains("\t") || $0.contains("\"") {

				let escaped = $0.replacingOccurrences(of: "\"", with: "\"\"")
				return "\"\(escaped)\""

			} else {
				return $0
			}
		}).joined(separator: "\t")

		return record
	}

}

//Delegate used to report conversion status
public protocol NVDataFormatterDelegate: AnyObject {

	///Report back the conversion percent
	func conversionPercent(current: Double) async

}
