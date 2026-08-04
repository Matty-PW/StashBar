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
    private var handler: () -> Void
    
    init(handler: @escaping () -> Void) {
        self.handler = handler
    }
    
    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
        installHandlerIfNeeded()
        
        // drop previous binding before claiming a new one
        if let existing = hotKeyRef {
            UnregisterEventHotKey(existing)
            hotKeyRef = nil
        }
        
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x53545348), id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        return status == noErr
        }
    
    
    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
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
    }
}
