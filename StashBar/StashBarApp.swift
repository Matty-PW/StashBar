//
//  StashBarApp.swift
//  StashBar
//
//  Created by Matty on 22/07/2026.
//

import SwiftUI
import SwiftData

@main
struct StashBarApp: App {
    var body: some Scene {
        // creates the status bar icon and dropdown popover
        MenuBarExtra("StashBar", systemImage: "tray.and.arrow.down.fill") {
            ContentView()
        }
        // allows full swiftUI interactivity
        .menuBarExtraStyle(.window)
    }
}
