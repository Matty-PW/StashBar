//
//  SettingsView.swift
//  StashBar
//
//  Created by Matty on 28/07/2026.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @StateObject private var launchAtLogin = LaunchAtLogin()
    
    var body: some View {
        Form {
            Toggle("Launch StashBar at login", isOn: $launchAtLogin.isEnabled)
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 140)
    }
}
