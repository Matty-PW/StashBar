//
//  StashBarApp.swift
//  StashBar
//
//  Created by Matty on 22/07/2026.
//

import SwiftUI

@main
struct StashBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
