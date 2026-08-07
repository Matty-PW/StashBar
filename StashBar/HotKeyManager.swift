//
//  HotKeyManager.swift
//  StashBar
//
//  Created by Matty on 27/07/2026.
//

import Foundation
import AppKit
import Carbon.HIToolbox

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var current: (keyCode: UInt32, modifiers: UInt32)?
    private var handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
        // re-registering whats already bound would collide with itself below
        if let current, current.keyCode == keyCode, current.modifiers == modifiers { return true }

        guard installHandlerIfNeeded() else { return false }

        // the old binding is kept until the new one is claimed so a rejected
        // combination leaves the previous shortcut working instead of nothing
        var newRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x53545348), id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &newRef)

        guard status == noErr, let newRef else { return false }

        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = newRef
        current = (keyCode, modifiers)
        return true
    }


    private func installHandlerIfNeeded() -> Bool {
        guard eventHandler == nil else { return true }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handler()
                return noErr

            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        return status == noErr
    }
}
