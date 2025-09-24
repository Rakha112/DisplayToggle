//
//  MainMenuView.swift
//  DisplayToggle
//
//  Created by Rakha Wibowo on 21/09/25.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var displayManager: DisplayManager
    @Binding var currentView: DisplayMenuView.ActiveView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach($displayManager.displays) { $display in
                HStack {
                    Image(systemName: display.iconName)
                        .foregroundColor(.secondary)
                        .frame(width: 25, alignment: .center)
                    Text(display.name)
                    Spacer()
                    Toggle("", isOn: $display.isOn)
                        .toggleStyle(.switch)
                        .onChange(of: display.isOn) { _, newState in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if newState {
                                    displayManager.reconnectDisplay(id: display.id)
                                } else {
                                    displayManager.disconnectDisplay(id: display.id)
                                }
                            }
                        }
                        .disabled(
                            displayManager.displays.filter { $0.isOn }.count == 1
                            && display.isOn
                        )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 9)
            }
            
            Divider().padding(.vertical, 4)
            
            Button(action: {
                Task {
                    print("All Displays On clicked")
                    displayManager.loadAndRestoreDisplays()
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        displayManager.loadAndRestoreDisplays()
                    }
                }
            }) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .frame(width: 25, alignment: .center)
                    Text("All Displays On")
                    Spacer()
                }
            }
            .buttonStyle(HoverButtonStyle())
            
            Button(action: { currentView = .preferences }) {
                HStack {
                    Image(systemName: "gearshape")
                        .frame(width: 25, alignment: .center)
                    Text("Preferences")
                    Spacer()
                }
            }
            .buttonStyle(HoverButtonStyle())
            
            Button(action: {
                displayManager.loadAndRestoreDisplays()
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power.circle.fill")
                        .frame(width: 25, alignment: .center)
                    Text("Exit Application")
                    Spacer()
                }
                .foregroundColor(.red)
            }
            .buttonStyle(HoverButtonStyle())
        }
        .padding(5)
        .frame(width: 320)
    }
}

struct HoverButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(isHovering ? 0.1 : 0))
            )
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
    }
}

