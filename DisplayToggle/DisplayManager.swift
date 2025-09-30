//
//  DisplayManager.swift
//  DisplayToggle
//
//  Created by Rakha Wibowo on 18/09/25.
//

import SwiftUI
import CoreGraphics
import Combine

enum DisplayManagerError: Error {
    case configurationFailed(String)
    case getDisplayListFailed(CGError)
}

class DisplayManager: ObservableObject {
    @Published var displays: [Display] = []
    
    private var isConfiguringInternally: Bool = false
    
    @Published var autoDisableBuiltInDisplay: Bool {
        didSet {
            UserDefaults.standard.set(autoDisableBuiltInDisplay, forKey: "autoDisableBuiltInDisplay")
            if autoDisableBuiltInDisplay {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.handleAutoDisableBuiltInDisplay()
                }
            }
        }
    }

    init() {
        self.autoDisableBuiltInDisplay = UserDefaults.standard.bool(forKey: "autoDisableBuiltInDisplay")
        loadAndRestoreDisplays {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.handleAutoDisableBuiltInDisplay()
            }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    
    @objc private func screenParametersDidChange(notification: NSNotification) {
        guard !isConfiguringInternally else {
            print("Screen parameters changed internally, skipping full refresh.")
            return
        }
        
        print("Screen parameters changed externally! Auto-refreshing display list.")
        do {
            let onlineDisplayIDs = try getOnlineDisplayIDs()
            
            DispatchQueue.main.async {
                self.updatePublishedDisplays(from: onlineDisplayIDs)
                self.handleAutoDisableBuiltInDisplay()
            }
            
        } catch {
            print("Failed to load displays: \(error)")
        }
    }
    
    private func handleAutoDisableBuiltInDisplay() {
        guard autoDisableBuiltInDisplay else { return }
        
        guard let builtIn = displays.first(where: { $0.isBuiltIn }) else {
            print("No built-in display detected.")
            return
        }
        
        let externalExists = displays.contains(where: { !$0.isBuiltIn && $0.isOn })
        
        if externalExists {
            if builtIn.isOn {
                print("External display detected, disabling builtin display...")
                disconnectDisplay(id: builtIn.id)
            }
        } else {
            if !builtIn.isOn {
                print("No external display, enabling builtin display...")
                reconnectDisplay(id: builtIn.id)
            }
        }
    }

    func disconnectDisplay(id: CGDirectDisplayID) {
        configureDisplay(id: id, isEnabled: false)
    }

    func reconnectDisplay(id: CGDirectDisplayID) {
        configureDisplay(id: id, isEnabled: true)
    }
    
    func loadAndRestoreDisplays(completion: (() -> Void)? = nil) {
        do {
            let allDisplayIDs = try getAllDisplayIDs()
            
            restoreOfflineDisplays(from: allDisplayIDs)
            
            let onlineDisplayIDs = try getOnlineDisplayIDs()
            
            DispatchQueue.main.async {
                self.updatePublishedDisplays(from: onlineDisplayIDs)
                completion?()
            }
            
            
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
        self.isConfiguringInternally = true
        
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config = config else {
            print("Failed to begin display configuration.")
            self.isConfiguringInternally = false
            return
        }

        let status = CGSConfigureDisplayEnabled(config, id, isEnabled)

        if status == .success {
            print("\(isEnabled ? "Enable" : "Disable") command for display \(id) sent successfully. Finalizing...")
            CGCompleteDisplayConfiguration(config, .permanently)
            
            DispatchQueue.main.async {
                if let index = self.displays.firstIndex(where: { $0.id == id }) {
                    self.displays[index].isOn = isEnabled
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isConfiguringInternally = false
            }
        } else {
            print("Failed to send \(isEnabled ? "enable" : "disable") command. Cancelling. Error: \(status.rawValue)")
            CGCancelDisplayConfiguration(config)
            self.isConfiguringInternally = false
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
    
    private func getOnlineDisplayIDs() throws -> [CGDirectDisplayID] {
        var displayCount: UInt32 = 0
        
        var result = CGGetOnlineDisplayList(0, nil, &displayCount)
        guard result == .success else {
            print("Failed to get online display count. Error: \(result)")
            throw DisplayManagerError.getDisplayListFailed(result)
        }

        var onlineIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        
        result = CGGetOnlineDisplayList(displayCount, &onlineIDs, &displayCount)
        guard result == .success else {
            print("Failed to get online display list. Error: \(result)")
            throw DisplayManagerError.getDisplayListFailed(result)
        }
        
        print("Found \(displayCount) online displays.")
        return onlineIDs
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
