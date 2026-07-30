//
//  StatusDropView.swift
//  StashBar
//
//  Created by Matty on 30/07/2026.
//

import Foundation
import AppKit

// sits over the status item button and springs the panel open
// when a file drag hovers over the menu bar icon
final class StatusDropView: NSView {
    var onDragEntered: (() -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        onDragEntered?()
        return.copy
    }
    
    // let ordinary clicks reach the status item button underneath
    override func mouseDown(with event: NSEvent) {
        superview?.mouseDown(with: event)
    }
}
