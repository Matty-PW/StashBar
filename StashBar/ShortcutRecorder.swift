//
//  ShortcutRecorder.swift
//  StashBar
//
//  Created by Matty on 03/08/2026.
//

import Foundation
import SwiftUI
import AppKit
import Carbon.HIToolbox

final class ShortcutRecorderView: NSView {
    var onRecord: ((Shortcut) -> Void)?
    var onEnd: (() -> Void)?
    var onInvalid: ((String) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func resignFirstResponder() -> Bool {
        onEnd?()
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        // esc abandons recording without changing anything
        if Int(event.keyCode) == kVK_Escape {
            window?.makeFirstResponder(nil)
            return
        }
        
        let carbon = Self.carbonModifiers(from: event.modifierFlags)
        
        // reject are keys + shift only combos
        guard carbon != 0, carbon != UInt32(shiftKey) else {
            NSSound.beep()
            onInvalid?("Shortcuts need ⌘, ⌥ or ⌃")
            return
        }
        
        let shortcut = Shortcut(
            keyCode: UInt32(event.keyCode),
            modifiers: carbon,
            display: Self.display(for: event)
        )
        onRecord?(shortcut)
        window?.makeFirstResponder(nil)
    }
    
    // nsevent and carbon use different constants for the same modifiers
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        return result
    }
    
    static func display(for event: NSEvent) -> String {
        var s = ""
        // macos shows modifiers in this specific order
        if event.modifierFlags.contains(.control) { s += "⌃"}
        if event.modifierFlags.contains(.option) { s += "⌥"}
        if event.modifierFlags.contains(.shift) { s += "⇧"}
        if event.modifierFlags.contains(.command) { s += "⌘"}
        return s + keyName(for: event)
    }
    
    static func keyName(for event: NSEvent) -> String {
        switch Int(event.keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        default:
            return (event.charactersIgnoringModifiers ?? "?").uppercased()
            
        }
    }
}

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onRecord: (Shortcut) -> Void
    var onInvalid: (String) -> Void = {_ in }
    
    func makeNSView(context: Context) -> ShortcutRecorderView {
        ShortcutRecorderView()
    }
    
    func updateNSView(_ view: ShortcutRecorderView, context: Context) {
        view.onRecord = onRecord
        view.onInvalid = onInvalid
        view.onEnd = { isRecording = false }
        
        if isRecording, view.window?.firstResponder !== view {
            // deferred because changing responder during a swiftui update is unsafe
            DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        
        }
    }
}
