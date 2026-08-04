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
    
    private static func load() -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil}
        return try? JSONDecoder().decode(Shortcut.self, from: data)
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
