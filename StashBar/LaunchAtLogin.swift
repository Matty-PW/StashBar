//
//  LaunchAtLogin.swift
//  StashBar
//
//  Created by Matty on 28/07/2026.
//

import Foundation
import ServiceManagement
import Combine

final class LaunchAtLogin: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { apply() }
    }
    
    init() {
        // read the real system state so toggle cant drift out of sync
        isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    
    private func apply() {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login change failed: \(error)")
        }
    }
}
