//
//  StashBarTests.swift
//  StashBarTests
//
//  Created by Matty on 22/07/2026.
//

import Testing
import AppKit
import Carbon.HIToolbox
@testable import StashBar

// covers the pure logic only. anything touching the hotkey registry, the
// pasteboard or the notes bridge needs a running app to mean anything.
// the app target builds with SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor,
// so its types are main actor isolated and the suites have to match

@MainActor
struct TitleTests {
    let exporter = ExportManager()

    @Test func usesFirstNonEmptyLine() {
        #expect(exporter.title(from: "Shopping list\nmilk\neggs") == "Shopping list")
    }

    @Test func skipsLeadingBlankLines() {
        #expect(exporter.title(from: "\n\n  Real title\nbody") == "Real title")
    }

    @Test func stripsMarkdownHeadingMarkers() {
        #expect(exporter.title(from: "## Heading") == "Heading")
        #expect(exporter.title(from: "###   Spaced") == "Spaced")
    }

    @Test func fallsBackToATimestampWhenThereIsNoText() {
        #expect(exporter.title(from: "").hasPrefix("StashBar "))
        #expect(exporter.title(from: "   \n  ").hasPrefix("StashBar "))
        // a heading marker with nothing after it is still empty
        #expect(exporter.title(from: "#").hasPrefix("StashBar "))
    }
}

@MainActor
struct ShortcutTests {
    @Test func survivesACodableRoundTrip() throws {
        let encoded = try JSONEncoder().encode(Shortcut.cmdShiftS)
        let decoded = try JSONDecoder().decode(Shortcut.self, from: encoded)
        #expect(decoded == .cmdShiftS)
    }

    @Test func presetsAreNotReserved() {
        for preset in Shortcut.presets {
            #expect(preset.reservedReason == nil, "\(preset.display) should be selectable")
        }
    }

    @Test func systemCombinationsAreRejected() {
        let spotlight = Shortcut(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey), display: "⌘Space")
        let quit = Shortcut(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey), display: "⌘Q")
        let switcher = Shortcut(keyCode: UInt32(kVK_Tab), modifiers: UInt32(cmdKey), display: "⌘⇥")

        #expect(spotlight.reservedReason != nil)
        #expect(quit.reservedReason != nil)
        #expect(switcher.reservedReason != nil)
    }

    @Test func modifiersAreMatchedExactlyNotAsASubset() {
        // ⌘⌥⇧S shares the cmd bit with ⌘Q but is a perfectly good shortcut
        let ok = Shortcut(
            keyCode: UInt32(kVK_ANSI_Q),
            modifiers: UInt32(cmdKey | optionKey | shiftKey),
            display: "⌘⌥⇧Q"
        )
        #expect(ok.reservedReason == nil)
    }
}

@MainActor
struct CarbonModifierTests {
    @Test func mapsEachNSEventFlagToItsCarbonBit() {
        #expect(ShortcutRecorderView.carbonModifiers(from: [.command]) == UInt32(cmdKey))
        #expect(ShortcutRecorderView.carbonModifiers(from: [.shift]) == UInt32(shiftKey))
        #expect(ShortcutRecorderView.carbonModifiers(from: [.option]) == UInt32(optionKey))
        #expect(ShortcutRecorderView.carbonModifiers(from: [.control]) == UInt32(controlKey))
    }

    @Test func combinesFlags() {
        #expect(ShortcutRecorderView.carbonModifiers(from: [.command, .shift]) == UInt32(cmdKey | shiftKey))
    }

    @Test func ignoresModifiersCarbonDoesntCarry() {
        #expect(ShortcutRecorderView.carbonModifiers(from: [.capsLock, .function]) == 0)
    }
}
