//
//  SettingsView.swift
//  StashBar
//
//  Created by Matty on 28/07/2026.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    var onShortcutChanged: (Shortcut) -> Bool = { _ in true }
    
    @StateObject private var launchAtLogin = LaunchAtLogin()
    @StateObject private var store = ShortcutStore()
    @State private var isRecording = false
    @State private var conflictMessage: String?
    
    var body: some View {
        Form {
            Toggle("Launch StashBar at login", isOn: $launchAtLogin.isEnabled)
            
            LabeledContent("Shortcut") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Button(isRecording ? "Type a shortcut…" : store.shortcut.display) {
                            isRecording = true
                        }
                        .frame(minWidth: 120)
                        .overlay(
                            ShortcutRecorder(
                                isRecording: $isRecording,
                                onRecord: {apply($0) },
                                onInvalid: { conflictMessage = $0 }
                            )
                            .allowsHitTesting(false)
                        )
                        
                        Menu("Presets") {
                            ForEach(Shortcut.presets, id: \.display) { preset in Button(preset.display) {apply(preset) }
                            }
                        }
                        .fixedSize()
                    }
                    
                    Text(conflictMessage ?? "Shortcuts need ⌘, ⌥ or ⌃. Some combinations are reserved by macOS.")
                        .font(.caption)
                        .foregroundColor(conflictMessage == nil ? .secondary : .red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 220)
    }
    
    private func apply(_ newValue: Shortcut) {
        if let reason = newValue.reservedReason {
            conflictMessage = reason
            return
        }

        conflictMessage = nil
        let previous = store.shortcut
        store.shortcut = newValue

        guard onShortcutChanged(newValue) else {
            // something else owns that combination so put the old one back
            store.shortcut = previous
            _ = onShortcutChanged(previous)
            conflictMessage = "\(newValue.display) is already in use by another app"
            return
        }
    }
}
