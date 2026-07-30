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
    private var settingsWindow: NSWindow?
    
    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 140),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "StashBar Settings"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.center()
            window.isReleasedWhenClosed = false // reuse it on open
            settingsWindow = window
            
            window.contentView = NSHostingView(rootView: SettingsView(
                onHotKeyChanged: { [weak self] choice in
                    self?.hotKeyManager?.register(keyCode: choice.keyCode, modifiers: choice.modifiers)
                }
            ))
        }
        
        // agent apps arent active by default so window needs help to come forward
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "StashBar")
        
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel)
        
        panel = StashPanel()
        
        if let button = statusItem.button {
            let dropView = StatusDropView(frame: button.bounds)
            dropView.autoresizingMask = [.width, .height]
            dropView.onDragEntered = { [weak self] in
                guard let self, !self.panel.isVisible else { return }
                self.positionPanel()
                self.panel.orderFrontRegardless()
            }
            button.addSubview(dropView)
        }
        
        // NSHostingView puts swiftUI view inside the AppKit window
        let hosting = NSHostingView(rootView: ContentView(onShowSettings: { [weak self] in self?.showSettings()}))
        panel.setContentSize(hosting.fittingSize) // sizes the panel to fit the swift ui content
        panel.contentView = hosting
        
        let saved = UserDefaults.standard.string(forKey: "hotKeyChoice")
        let choice = saved.flatMap(HotKeyChoice.init(rawValue:)) ?? .cmdShiftS
        
        hotKeyManager = HotKeyManager { [weak self] in self?.togglePanel() }
        hotKeyManager?.register(keyCode: choice.keyCode, modifiers: choice.modifiers)
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
