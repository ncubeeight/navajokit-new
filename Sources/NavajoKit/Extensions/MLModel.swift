//
//  MLModel.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/13/25.
//

import CoreML

public extension MLModel {

	/**
		Convenience function for initializing compiled ML models within this framework as objects
		Parameters:
			- named: File name of the ML model without its extension
			- configuration: Any overrides to the default configuration
	*/
	static func loadModel(named: String, configuration: MLModelConfiguration = .init()) throws -> MLModel {

		let url = Bundle.module.url(forResource: named, withExtension: "mlmodelc")!

		return try MLModel(contentsOf: url, configuration: configuration)

	}

}
