//
//  DisplayMenuView.swift
//  DisplayToggle
//
//  Created by Rakha Wibowo on 18/09/25.
//

import SwiftUI

struct DisplayMenuView: View {
    @EnvironmentObject var displayManager: DisplayManager
    
    enum ActiveView {
        case main
        case preferences
    }
    
    @State var currentView: ActiveView = .main
    
    var body: some View {
        ZStack {
            switch currentView {
            case .main:
                MainMenuView(currentView: $currentView)
                    .environmentObject(displayManager)
                    .transition(.move(edge: .leading).combined(with: .opacity))

            case .preferences:
                PreferencesView(currentView: $currentView)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentView)
        .padding(.vertical, 8)
        .frame(width: 320)
    }
}

#Preview {
    DisplayMenuView()
}
