//
//  ExportManager.swift
//  StashBar
//
//  Created by Matty on 27/07/2026.
//

import Foundation
import AppKit
import Combine

final class ExportManager: ObservableObject {
    private let bookmarkKey = "exportFolderBookmark"
    
    @Published private(set) var folderName: String?
    
    init() {
        folderName = resolveFolder()?.lastPathComponent
    }
    
    // asks the user to pick a folder then store a bookmark so we can reach it again later
    func chooseFolder() {
        // panel is non activating, so the app may not be frontmost
        // without this the open pane can appear behind other windows
        NSApp.activate(ignoringOtherApps: true)
        
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Choose a folder for StashBar to save notes into"
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
            folderName = url.lastPathComponent
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }
    
    // turn the stored bookmark back into a usable url
    private func resolveFolder() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }
        
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale { print("Bookmark stale - folder was moved or renamed") }
            return url
        } catch {
            print("Failed to resolve bookmark \(error)")
            return nil
        }
    }
    
    // write text to a timestamped .md file in the chosen folder
    @discardableResult
    func exportMarkdown(_ text: String) -> Bool {
        guard let folder = resolveFolder() else { return false }
        
        // sandbox access must be explicitly opened and closed around the write
        guard folder.startAccessingSecurityScopedResource() else { return false }
        defer { folder.stopAccessingSecurityScopedResource() }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let fileURL = folder.appendingPathComponent("StashBar-\(formatter.string(from: Date())).md")
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Write failed: \(error)")
            return false
        }
    }
}
