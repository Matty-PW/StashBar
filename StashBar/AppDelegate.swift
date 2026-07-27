//
//  AppDelegate.swift
//  StashBar
//
//  Created by Matty on 27/07/2026.
//

import Foundation
import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: StashPanel!
    private var hotKeyManager: HotKeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "tray.full", accessibilityDescription: "StashBar")
        
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel)
        
        panel = StashPanel()
        
        // NSHostingView puts swiftUI view inside the AppKit window
        let hosting = NSHostingView(rootView: ContentView())
        panel.setContentSize(hosting.fittingSize) // sizes the panel to fit the swift ui content
        panel.contentView = hosting
        
        hotKeyManager = HotKeyManager { [weak self] in self?.togglePanel()
        }
        hotKeyManager?.register()
    }
    
    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            positionPanel()
            panel.orderFrontRegardless() // shows when app isnt active
            panel.makeKey()              // accepts keyboard input for the text editor
        }
    }
    
    private func positionPanel() {
        guard let buttonFrame = statusItem.button?.window?.frame else { return }
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(
            x: buttonFrame.midX - size.width / 2,
            y: buttonFrame.minY - size.height - 6
        ))
        
    }
}
