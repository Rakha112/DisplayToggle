//
//  DisplayToggleApp.swift
//  DisplayToggle
//
//  Created by Rakha Wibowo on 18/09/25.
//

import SwiftUI

@main
struct DisplayToggleApp: App {
    @StateObject private var displayManager = DisplayManager()

    var body: some Scene {
        MenuBarExtra {
            DisplayMenuView()
                .environmentObject(displayManager)
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.window)
    }
}
