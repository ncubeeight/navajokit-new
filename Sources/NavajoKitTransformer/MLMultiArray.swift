//
//  MLMultiArray.swift
//  NavajoKitTransformer
//
//  Created by Daniel Gump on 3/17/26.
//

import CoreML

extension MLMultiArray {

	func index(_ indices: [Int]) -> Int {

		var offset = 0

		for i in 0..<indices.count {
			offset += indices[i] * strides[i].intValue
		}

		return offset
	}

	func value(_ indices: [Int]) -> Float {

		let offset = index(indices)

		return dataPointer.assumingMemoryBound(to: Float.self)[offset]
	}

	func setValue(_ value: Float, _ indices: [Int]) {

		let offset = index(indices)

		dataPointer.assumingMemoryBound(to: Float.self)[offset] = value
	}
}
