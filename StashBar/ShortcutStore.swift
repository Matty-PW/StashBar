//
//  ShortcutStore.swift
//  StashBar
//
//  Created by Matty on 03/08/2026.
//

import Foundation
import Combine

final class ShortcutStore: ObservableObject {
    private static let key = "hotKeyShortcut"

    @Published var shortcut: Shortcut {
        didSet { save() }
    }

    init() {
        shortcut =  Self.load() ?? .cmdShiftS
    }

    // the app delegate needs this at launch before any settings ui exists so it
    // reads through here rather than keeping its own copy of the key and encoding
    static func load() -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil}
        return try? JSONDecoder().decode(Shortcut.self, from: data)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
