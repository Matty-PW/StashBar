//
//  HotKeyChoice.swift
//  StashBar
//
//  Created by Matty on 30/07/2026.
//

import Foundation
import Carbon.HIToolbox

enum HotKeyChoice: String, CaseIterable, Identifiable {
    case cmdShiftS
    case optionSpace
    case ctrlOptionS
    case cmdShiftSpace
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .cmdShiftS: return "⌘⇧S"
        case .optionSpace: return "⌥Space"
        case .ctrlOptionS: return "⌃⌥S"
        case .cmdShiftSpace: return "⌘⇧Space"
        }
    }
    
    var keyCode: UInt32 {
        switch self {
        case .cmdShiftS, .ctrlOptionS: return UInt32(kVK_ANSI_S)
        case .optionSpace, .cmdShiftSpace: return UInt32(kVK_Space)
        }
    }
    
    var modifiers: UInt32 {
        switch self {
        case .cmdShiftS: return UInt32(cmdKey | shiftKey)
        case .optionSpace: return UInt32(optionKey)
        case .ctrlOptionS: return UInt32(controlKey | optionKey)
        case .cmdShiftSpace: return UInt32(cmdKey | shiftKey)
        }
    }
}
