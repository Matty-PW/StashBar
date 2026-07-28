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
        
        let fileURL = uniqueURL(in: folder, basename: filename(from: title(from: text)))
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Write failed: \(error)")
            return false
        }
    }
    
    private func escapedForAppleScript(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    @discardableResult
    func exportToAppleNotes(_ text: String) -> Bool {
        print("exportToAppleNotes called")
        let noteTitle = title(from: text)
        
        // notes stores bodies as html so escape markup and convert new lines
        let htmlBody = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        
        let source = """
        tell application "Notes"
            make new note with properties {name:"\(escapedForAppleScript(noteTitle))", body:"\(escapedForAppleScript(htmlBody))"}
        end tell
        """
        
        guard let script = NSAppleScript(source: source) else {
            print("could not compile applescript")
            return false
        }
        print("running applescript:\n\(source)")
        
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        
        if let error {
            print("AppleScript failed: \(error)")
            return false
        }
        return true
    }
    
    
    // derives a filename safe title from the first non empty line of space
    // made internal not private because notes and notion reuse it
    func title(from text: String) -> String {
        let firstLine = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map(String.init) ?? ""
        
        var title = firstLine.trimmingCharacters(in: .whitespaces)
        
        // strip markdown heading markers
        while title.hasPrefix("#") { title.removeFirst() }
        title = title.trimmingCharacters(in: .whitespaces)
        
        guard !title.isEmpty else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            return "StashBar \(formatter.string(from: Date()))"
        }
        return title
    }
    
    // a filename safe version of a title
    private func filename(from title: String) -> String {
        let illegal = CharacterSet(charactersIn: "/\\:?%*\"<>")
        var name = title.components(separatedBy: illegal).joined(separator: "-")
        name = name.split(whereSeparator: { $0.isWhitespace }).joined(separator: "-")
        if name.count > 50 { name = String(name.prefix(50)) }
        return name.isEmpty ? "StashBar-note" : name
    }
    
    
    // returns a url that doesnt already exist by adding -2, -3 and so on if needed
    private func uniqueURL(in folder: URL, basename: String) -> URL {
        var candidate = folder.appendingPathComponent("\(basename).md")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(basename)-\(counter).md")
            counter += 1
        }
        return candidate
    }
    
}
