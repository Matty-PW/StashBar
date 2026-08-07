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
            let hosting = NSHostingView(rootView: SettingsView(
                onShortcutChanged: { [weak self] shortcut in
                    self?.hotKeyManager?.register(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers) ?? false
                }
            ))

            // sized from the content rather than a hardcoded rect
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.delegate = self
            window.title = "StashBar Settings"
            window.contentView = hosting
            // the window is rebuilt on each open so the shortcut recorder starts clean
            // this only stops appkit freeing it before windowWillClose runs
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
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

        let glass = NSGlassEffectView(frame: NSRect(origin: .zero, size: size))
        glass.style = .regular
        glass.cornerRadius = StashPanel.cornerRadius

        hosting.frame = glass.bounds
        hosting.autoresizingMask = [.width, .height]
        glass.contentView = hosting

        
        let container = NSView(frame: NSRect(origin: .zero, size: size))
        container.wantsLayer = true
        container.layer?.cornerRadius = StashPanel.cornerRadius
        container.layer?.cornerCurve = .continuous
        container.layer?.masksToBounds = true
        glass.autoresizingMask = [.width, .height]
        container.addSubview(glass)

        panel.setContentSize(size)
        panel.contentView = container
        // shadow is cached so it needs recomputing once the rounded content is in place
        panel.invalidateShadow()

        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "StashBar")
        
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel)
        
        
        if let button = statusItem.button {
            let dropView = StatusDropView(frame: button.bounds)
            dropView.autoresizingMask = [.width, .height]

            dropView.onDragEntered = { [weak self] in
                guard let self else { return }
                self.springCloseWork?.cancel()

                // a panel that was already up wasnt opened by this drag so this
                // drag doesnt get to close it either
                guard !self.panel.isVisible else {
                    self.panelOpenedBySpring = false
                    return
                }

                self.positionPanel()
                self.panel.orderFrontRegardless()
                self.panelOpenedBySpring = true
            }

            
            dropView.onDragExited = { [weak self] in
                guard let self, self.panelOpenedBySpring else { return }

                let work = DispatchWorkItem { [weak self] in
                    guard let self, self.panel.isVisible else { return }
                    // dont close if the cursor has moved onto the panel to drop
                    guard !self.panel.frame.contains(NSEvent.mouseLocation) else { return }
                    self.panel.orderOut(nil)
                    self.panelOpenedBySpring = false
                }
                self.springCloseWork?.cancel()
                self.springCloseWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
            }

            button.addSubview(dropView)
        }

        let saved = ShortcutStore.load() ?? .cmdShiftS

        hotKeyManager = HotKeyManager { [weak self] in self?.togglePanel() }
        // a shortcut that cant be claimed would otherwise just be silently dead
        statusItem.button?.toolTip = hotKeyManager?.register(keyCode: saved.keyCode, modifiers: saved.modifiers) == true
            ? "StashBar (\(saved.display))"
            : "StashBar — \(saved.display) is unavailable, another app has it"
    }

    @objc private func togglePanel() {
        // opening or closing by hand takes the panel out of the springs hands
        springCloseWork?.cancel()
        panelOpenedBySpring = false

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            positionPanel()
            panel.orderFrontRegardless() // shows when app isnt active
            panel.makeKey()              // accepts keyboard input for the text editor
        }
    }

    private func positionPanel() {
        guard let buttonWindow = statusItem.button?.window else { return }
        let buttonFrame = buttonWindow.frame
        let size = panel.frame.size

        var origin = NSPoint(
            x: buttonFrame.midX - size.width / 2,
            y: buttonFrame.minY - size.height - 6
        )

        // a status item near the end of the menu bar would hang off the screen
        if let visible = (buttonWindow.screen ?? NSScreen.main)?.visibleFrame {
            let margin: CGFloat = 8
            origin.x = min(max(origin.x, visible.minX + margin), visible.maxX - size.width - margin)
            origin.y = max(origin.y, visible.minY + margin)
        }

        panel.setFrameOrigin(origin)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSWindow) === settingsWindow else { return }
        settingsWindow = nil
    }
}
