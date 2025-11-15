//
//  Bundle.swift
//  NavajoKit
//
//  Created by Daniel Gump on 11/13/25.
//

import Foundation

public extension Bundle {

	///Custom getter to reference this frame from within containing project
	static var navajoKit: Bundle {
		return Bundle.module
	}

}
