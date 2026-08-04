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
