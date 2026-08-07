//
//  FileDragSource.swift
//  StashBar
//
//  Created by Matty on 27/07/2026.
//

import Foundation
import SwiftUI
import AppKit

// transparent appkit view that starts a file drag and reports the outcome
final class FileDragSourceView: NSView, NSDraggingSource {
    var url : URL?
    var onDragCompleted: (() -> Void)?

    // the panel is non activating so it often isnt the key window without this
    // the first click is spent activating it and the drag needs a second press
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // tells macos what kind of drag this is    .copy means source file is left alone
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let url else { return }
        
        // NSDraggingItem is the payload. NSURL can write itself to the pasteboard
        // which is what lets finder and mail understand the drop
        let item = NSDraggingItem(pasteboardWriter: url as NSURL)
        
        // gives the drag something to look like while in flight
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        item.setDraggingFrame(bounds, contents: icon)
        
        beginDraggingSession(with: [item], event: event, source: self)
    }
    
    // called when the drag finishes wherever it lands
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        guard operation != [] else { return }
        onDragCompleted?()
    }
    
    // let right clicks fall through so swiftUIs context menu still works
    override func rightMouseDown(with event: NSEvent) {
        nextResponder?.rightMouseDown(with: event)
    }
}

struct FileDragSource: NSViewRepresentable {
    let url : URL
    let onDragCompleted: () -> Void
    
    func makeNSView(context: Context) -> FileDragSourceView {
        let view = FileDragSourceView()
        view.url = url
        view.onDragCompleted = onDragCompleted
        return view
    }
    
    func updateNSView(_ nsView: FileDragSourceView, context: Context) {
        nsView.url = url
        nsView.onDragCompleted = onDragCompleted
    }
}
