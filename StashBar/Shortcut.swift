//
//  Shortcut.swift
//  StashBar
//
//  Created by Matty on 03/08/2026.
//

import Foundation
import Carbon.HIToolbox

struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32 // carbon modifier mask
    var display: String
}

extension Shortcut {
    static let cmdShiftS = Shortcut(keyCode: UInt32(kVK_ANSI_S), modifiers: UInt32(cmdKey | shiftKey), display: "⌘⇧S")
    
    static let optionSpaceS = Shortcut(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey), display: "⌥Space")
    
    static let ctrlOptionS = Shortcut(keyCode: UInt32(kVK_ANSI_S), modifiers: UInt32(controlKey | optionKey), display: "⌃⌥S")
    
    static let presets: [Shortcut] = [.cmdShiftS, .optionSpaceS, .ctrlOptionS]
}

extension Shortcut {
    // RegisterEventHotKey returns noErr for combinations macos or every app
    // already owns and then the handler simply never fires
    // the well known ones are rejected up front instead of failing silently at registration
    var reservedReason: String? {
        let cmd = UInt32(cmdKey)
        let shift = UInt32(shiftKey)
        let option = UInt32(optionKey)

        switch (modifiers, Int(keyCode)) {
        case (cmd, kVK_Space), (cmd | option, kVK_Space), (cmd | shift, kVK_Space):
            return "\(display) belongs to Spotlight"
        case (cmd, kVK_Tab), (cmd | shift, kVK_Tab):
            return "\(display) belongs to the app switcher"
        case (cmd, kVK_Escape), (cmd | option, kVK_Escape):
            return "\(display) belongs to Force Quit"
        case (cmd, kVK_ANSI_Q):
            return "\(display) would override Quit"
        case (cmd, kVK_ANSI_W):
            return "\(display) would override Close Window"
        case (cmd, kVK_ANSI_M):
            return "\(display) would override Minimise"
        case (cmd, kVK_ANSI_H), (cmd | option, kVK_ANSI_H):
            return "\(display) would override Hide"
        default:
            return nil
        }
    }
}
