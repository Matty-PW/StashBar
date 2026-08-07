//
//  ExportManager.swift
//  StashBar
//
//  Created by Matty on 27/07/2026.
//

import Foundation
import AppKit
import Combine

enum ExportStatus: Equatable {
    case success(String)
    case failure(String)
    
    var message: String {
        switch self {
        case .success(let m), .failure(let m): return m
        }
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}


// NSAppleScript isnt thread safe so scripts go through this actor rather than
// running concurrently.
// being an actor also keeps them off the main thread
// which matters because launching notes can take seconds
private actor AppleScriptRunner {
    // nil means it worked. only strings cross the actor boundary so there is
    // no question about what is safe to send
    func run(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else {
            return "Couldn't build the Notes request"
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)

        guard let error else { return nil }
        return "Notes: " + (error[NSAppleScript.errorBriefMessage] as? String ?? "Unknown error")
    }
}


final class ExportManager: ObservableObject {
    private let bookmarkKey = "exportFolderBookmark"
    private let scriptRunner = AppleScriptRunner()

    @Published private(set) var folderName: String?
    @Published private(set) var status: ExportStatus?

    // identifies the current message so its timer cant clear a newer one
    private var statusToken = 0

    init() {
        folderName = resolveFolder()?.lastPathComponent
    }

    // shows message then clears after a few seconds
    private func report(_ newStatus: ExportStatus) {
        statusToken &+= 1
        let token = statusToken
        status = newStatus

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            // comparing tokens rather than values so reporting the same message
            // twice in a row doesnt let the first timer clear the second
            guard let self, self.statusToken == token else { return }
            self.status = nil
        }
    }

    // asks the user to pick a folder then store a bookmark so we can reach it again later
    @discardableResult
    func chooseFolder() -> Bool {
        // panel is non activating so the app may not be at the front
        // without this the open dropdown can appear behind other windows
        NSApp.activate(ignoringOtherApps: true)
        
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Choose a folder for StashBar to save notes into"
        
        guard panel.runModal() == .OK, let url = panel.url else { return false }

        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
            folderName = url.lastPathComponent
            status = nil
            return true
        } catch {
            report(.failure("Couldn't save access to that folder"))
            return false
        }
    }
    
    // turns the stored bookmark back into a usable url
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
            if isStale {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let fresh = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                        UserDefaults.standard.set(fresh, forKey: bookmarkKey)
                    }
                }
            }
            return url
        } catch {
            print("Failed to resolve bookmark \(error)")
            return nil
        }
    }
    
    // writes text to a timestamped .md file in the chosen folder
    @discardableResult
    func exportMarkdown(_ text: String) -> Bool {
        guard let folder = resolveFolder() else {
            let hadFolder = UserDefaults.standard.data(forKey: bookmarkKey) != nil
            // the name shown in the ui is now a lie, so stop claiming it
            folderName = nil
            report(.failure(hadFolder
                ? "Can't reach that folder - choose it again"
                : "Choose a folder first"))
            return false
        }
        
        // sandbox access must be explicitly opened and closed around the write
        guard folder.startAccessingSecurityScopedResource() else {
            report(.failure("Couldn't access that folder"))
            return false
        }
        defer { folder.stopAccessingSecurityScopedResource() }
        
        let fileURL = uniqueURL(in: folder, basename: filename(from: title(from: text)))
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            report(.success("Saved \(fileURL.lastPathComponent)"))
            return true
        } catch {
            report(.failure("Save failed: \(error.localizedDescription)"))
            return false
        }
    }
    
    private func escapedForAppleScript(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\n")
    }

    // reports through `status` rather than returning because launching notes can
    // take seconds and that cant be allowed to block the main thread
    func exportToAppleNotes(_ text: String) {
        let noteTitle = title(from: text)

        // notes stores bodies as html so escape markup and convert new lines.
        let htmlBody = bodyWithoutTitle(text)
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\r\n", with: "<br>")
            .replacingOccurrences(of: "\n", with: "<br>")
            .replacingOccurrences(of: "\r", with: "<br>")

        let source = """
        tell application "Notes"
            make new note with properties {name:"\(escapedForAppleScript(noteTitle))", body:"\(escapedForAppleScript(htmlBody))"}
        end tell
        """

        Task { [weak self] in
            guard let self else { return }

            if let failure = await self.scriptRunner.run(source) {
                self.report(.failure(failure))
            } else {
                self.report(.success("Sent to Apple Notes"))
            }
        }
    }
    
    
    // derives a filename safe title from the first non empty line of text
    // made internal not private because notes reuse it
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
    
    // the note text without the title line so notes doesnt show it twice
    private func bodyWithoutTitle(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        guard let titleIndex = lines.firstIndex(where: {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }) else {
            return ""
        }
        return lines[(titleIndex + 1)...].joined(separator: "\n")
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
