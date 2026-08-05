//
//  StashPanel.swift
//  StashBar
//
//  Created by Matty on 27/07/2026.
//

import Foundation
import AppKit

final class StashPanel: NSPanel {
    // matches the glass corner in AppDelegate so the window shadow follows the same shape
    static let cornerRadius: CGFloat = 16

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 380),
            // no .titled: a titled window adds its own frame view, which nests a second
            // set of corners inside the glass and shapes the shadow to the full rect
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    // borderless style panels refuse key status by default
    // without this texteditor wont accept typing
    override var canBecomeKey: Bool { true }
    
}
