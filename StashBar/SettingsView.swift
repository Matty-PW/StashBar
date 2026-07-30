//
//  SettingsView.swift
//  StashBar
//
//  Created by Matty on 28/07/2026.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    var onHotKeyChanged: (HotKeyChoice) -> Void = { _ in }
    
    @StateObject private var launchAtLogin = LaunchAtLogin()
    @AppStorage("hotKeyChoice") private var hotKeyChoice: HotKeyChoice = .cmdShiftS
    
    var body: some View {
        Form {
            Toggle("Launch StashBar at login", isOn: $launchAtLogin.isEnabled)
            
            Picker("Show StashBar", selection: $hotKeyChoice) {
                ForEach(HotKeyChoice.allCases) { choice in
                    Text(choice.label).tag(choice)
                }
            }
            .onChange(of: hotKeyChoice) { _, newValue in
                onHotKeyChanged(newValue)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 140)
    }
}
