//
//  PreferencesView.swift
//  DisplayToggle
//
//  Created by Rakha Wibowo on 21/09/25.
//

import SwiftUI
import ServiceManagement

struct OnChangeCompatModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let initial: Bool
    let action: (_ oldValue: Value?, _ newValue: Value) -> Void

    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.onChange(of: value, initial: initial) { old, new in
                action(old, new)
            }
        } else {
            content.onChange(of: value) { new in
                action(nil, new)
            }
        }
    }
}

extension View {
    func onChangeCompat<Value: Equatable>(
        of value: Value,
        initial: Bool = false,
        perform action: @escaping (_ oldValue: Value?, _ newValue: Value) -> Void
    ) -> some View {
        modifier(OnChangeCompatModifier(value: value, initial: initial, action: action))
    }
}

struct PreferencesView: View {
    @Binding var currentView: DisplayMenuView.ActiveView
    @EnvironmentObject var displayManager: DisplayManager

    @State private var launchAtLogin = false
    @State private var requiresApproval = false
    @State private var isBusy = false
    
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: { currentView = .main }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }

                Spacer()
            }
            .overlay(
                Text("Preferences")
                    .font(.headline)
            )
            .padding(.bottom, 15)

            Divider().padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Auto launch at login")
                        Spacer()
                        Toggle("", isOn: $launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .disabled(isBusy)
                            .onChangeCompat(of: launchAtLogin) { _, newValue in
                                setLaunchAtLogin(newValue)
                            }
                    }

                    if requiresApproval {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("Requires approval in System Settings > Login Items.")
                            Spacer()
                            if #available(macOS 13.0, *) {
                                Button("Open") {
                                    SMAppService.openSystemSettingsLoginItems()
                                }
                            }
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Auto disable built-in display")
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .help("When an external display is connected, the built-in display will be turned off.")
                        Spacer()
                        Toggle("", isOn: $displayManager.autoDisableBuiltInDisplay)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onDisappear {
            currentView = .main
        }
        .onChangeCompat(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                refreshLaunchAtLoginStatus()
            }
        }
    }
    
    private func refreshLaunchAtLoginStatus() {
        guard #available(macOS 13.0, *) else { return }
        let status = SMAppService.mainApp.status
        launchAtLogin = (status == .enabled)
        requiresApproval = (status == .requiresApproval)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        guard #available(macOS 13.0, *), !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin.toggle()
            return
        }

        refreshLaunchAtLoginStatus()
    }
}
