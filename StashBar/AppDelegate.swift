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
    private var springCloseWork: DispatchWorkItem?
    private var panelOpenedBySpring = false
    
    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 140),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.delegate = self
            window.title = "StashBar Settings"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.center()
            window.isReleasedWhenClosed = false // reuse it on open
            settingsWindow = window
            
            window.contentView = NSHostingView(rootView: SettingsView(
                onShortcutChanged: { [weak self] shortcut in
                    self?.hotKeyManager?.register(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers) ?? false
                }
            ))
        }
        
        // agent apps arent active by default so window needs help to come forward
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        panel = StashPanel()
        
        let hosting = NSHostingView(rootView: ContentView(onShowSettings: {[weak self] in self?.showSettings()
        }))
       
        let size = hosting.fittingSize

        // NSGlassEffectView owns its own shape, so no manual layer masking here.
        // it also only guarantees placement for contentView, not for added subviews.
        let glass = NSGlassEffectView(frame: NSRect(origin: .zero, size: size))
        glass.style = .regular
        glass.cornerRadius = StashPanel.cornerRadius

        hosting.frame = glass.bounds
        hosting.autoresizingMask = [.width, .height]
        glass.contentView = hosting

        // the window shadow is derived from the alpha of the content view's bounds, which
        // is square regardless of how the glass renders its own corners. without a
        // genuinely transparent-cornered silhouette the shadow squares off the corners
        // and reads as a hairline rectangle drawn outside the glass.
        let container = NSView(frame: NSRect(origin: .zero, size: size))
        container.wantsLayer = true
        container.layer?.cornerRadius = StashPanel.cornerRadius
        container.layer?.cornerCurve = .continuous
        container.layer?.masksToBounds = true
        glass.autoresizingMask = [.width, .height]
        container.addSubview(glass)

        panel.setContentSize(size)
        panel.contentView = container
        // shadow is cached, so it needs recomputing once the rounded content is in place
        panel.invalidateShadow()

        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "StashBar")
        
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel)
        
        
        if let button = statusItem.button {
            let dropView = StatusDropView(frame: button.bounds)
            dropView.autoresizingMask = [.width, .height]
            dropView.onDragEntered = { [weak self] in
                guard let self, !self.panel.isVisible else { return }
                self.springCloseWork?.cancel()
                guard !self.panel.isVisible else { return }
                self.positionPanel()
                self.panel.orderFrontRegardless()
                self.panelOpenedBySpring = true
                
                dropView.onDragExited = { [weak self] in
                    guard let self, self.panelOpenedBySpring else { return }
                    
                    let work = DispatchWorkItem { [weak self] in
                        guard let self, self.panel.isVisible else { return }
                        // domt close if the cursor has moved onto the panel to drop
                        guard !self.panel.frame.contains(NSEvent.mouseLocation) else { return }
                        self.panel.orderOut(nil)
                        self.panelOpenedBySpring = false
                    }
                    self.springCloseWork?.cancel()
                    self.springCloseWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
                }
            }
            button.addSubview(dropView)
        }
        
        let saved = (try? JSONDecoder().decode(
            Shortcut.self,
            from: UserDefaults.standard.data(forKey: "hotKeyShortcut") ?? Data()
        )) ?? .cmdShiftS
        
        hotKeyManager = HotKeyManager { [weak self] in self?.togglePanel() }
        hotKeyManager?.register(keyCode: saved.keyCode, modifiers: saved.modifiers)
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

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSWindow) === settingsWindow else { return }
        settingsWindow = nil
    }
}
