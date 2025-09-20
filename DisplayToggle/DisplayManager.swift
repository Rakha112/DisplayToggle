//
//  DisplayManager.swift
//  DisplayToggle
//
//  Created by Rakha Wibowo on 18/09/25.
//

import SwiftUI
import AppKit
import CoreGraphics
import Combine

enum DisplayManagerError: Error {
    case configurationFailed(String)
    case getDisplayListFailed(CGError)
}

class DisplayManager: ObservableObject {
    @Published var displays: [Display] = []

    init() {
        loadAndRestoreDisplays()
    }
     
    func refreshDisplays() {
        loadAndRestoreDisplays()
    }
    
    func disconnectDisplay(id: CGDirectDisplayID) {
        configureDisplay(id: id, isEnabled: false)
    }

    func reconnectDisplay(id: CGDirectDisplayID) {
        configureDisplay(id: id, isEnabled: true)
    }
    
    func loadAndRestoreDisplays() {
        do {
            let allDisplayIDs = try getAllDisplayIDs()
            
            DispatchQueue.main.async {
                self.updatePublishedDisplays(from: allDisplayIDs)
            }
            
            restoreOfflineDisplays(from: allDisplayIDs)
            
        } catch {
            print("Failed to load displays: \(error)")
        }
    }
    
    private func updatePublishedDisplays(from displayIDs: [CGDirectDisplayID]) {
        let activeScreenNameMap = NSScreen.screens.reduce(into: [CGDirectDisplayID: String]()) { map, screen in
            let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            if let id = id {
                map[id] = screen.localizedName
            }
        }
        
        self.displays = displayIDs.map { id in
            let isEnabled = CGDisplayIsActive(id) != 0
            let isBuiltIn = CGDisplayIsBuiltin(id) != 0
            let displayName = activeScreenNameMap[id] ?? "Offline Display (\(id))"
            
            return Display(id: id, name: displayName, isOn: isEnabled, isBuiltIn: isBuiltIn)
        }
    }
    
    private func restoreOfflineDisplays(from displayIDs: [CGDirectDisplayID]) {
        for id in displayIDs where CGDisplayIsActive(id) == 0 {
            print("Found offline display, attempting to restore: \(id)")
            reconnectDisplay(id: id)
        }
    }

    private func configureDisplay(id: CGDirectDisplayID, isEnabled: Bool) {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config = config else {
            print("Failed to begin display configuration.")
            return
        }

        let status = CGSConfigureDisplayEnabled(config, id, isEnabled)

        if status == .success {
            print("\(isEnabled ? "Enable" : "Disable") command for display \(id) sent successfully. Finalizing...")
            CGCompleteDisplayConfiguration(config, .permanently)
        } else {
            print("Failed to send \(isEnabled ? "enable" : "disable") command. Cancelling. Error: \(status.rawValue)")
            CGCancelDisplayConfiguration(config)
        }
    }
    
    private func getAllDisplayIDs() throws -> [CGDirectDisplayID] {
        var displayCount: CInt = 0
        var status = CGSGetDisplayList(0, nil, &displayCount)
        guard status == .success else {
            throw DisplayManagerError.getDisplayListFailed(status)
        }

        var ids = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        status = CGSGetDisplayList(displayCount, &ids, &displayCount)
        guard status == .success else {
            throw DisplayManagerError.getDisplayListFailed(status)
        }

        return ids
    }
}
