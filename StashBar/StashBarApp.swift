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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // placeholder while AppDelegate own the actual UI
        Settings { EmptyView() }
    }
}
