//
//  MLModel.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/13/25.
//

import CoreML

public extension MLModel {

	static func loadModel(named: String, configuration: MLModelConfiguration = .init()) throws -> MLModel {

		let url = Bundle.module.url(forResource: named, withExtension: "mlmodelc")!

		return try MLModel(contentsOf: url, configuration: configuration)

	}

}
