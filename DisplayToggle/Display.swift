//
//  Display.swift
//  DisplayToggle
//
//  Created by Rakha Wibowo on 18/09/25.
//

import Foundation
import CoreGraphics

struct Display: Identifiable {
    let id: CGDirectDisplayID
    let name: String
    var isOn: Bool
    let isBuiltIn: Bool

    var iconName: String {
        return isBuiltIn ? "laptopcomputer" : "display"
    }
}
