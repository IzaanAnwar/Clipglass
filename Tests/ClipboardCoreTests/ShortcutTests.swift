import Foundation
import Testing
@testable import ClipboardCore

struct ShortcutTests {
    @Test func defaultIsValid() {
        #expect(Shortcut.defaultOpen.isValid)
        #expect(!Shortcut.defaultOpen.isReserved)
        #expect(Shortcut.defaultOpen.display == "⌃⌥V")
    }
    @Test func rejectsUnmodifiedOrNavigationKeys() {
        #expect(!Shortcut(keyCode: 9, modifiers: [], keyLabel: "V").isValid)
        #expect(!Shortcut(keyCode: 53, modifiers: .command, keyLabel: "Escape").isValid)
        #expect(!Shortcut(keyCode: 9, modifiers: .shift, keyLabel: "V").isValid)
        #expect(!Shortcut(keyCode: 200, modifiers: .command, keyLabel: "?").isValid)
    }
    @Test func protectsCommonEditingShortcuts() {
        for key: UInt32 in [0, 6, 7, 8, 9, 12, 13, 49] {
            #expect(Shortcut(keyCode: key, modifiers: .command, keyLabel: "key").isReserved)
        }
        #expect(!Shortcut.defaultOpen.isReserved)
    }
    @Test func shortcutSurvivesSerialization() throws {
        let shortcut = Shortcut(keyCode: 40, modifiers: [.command, .shift], keyLabel: "K")
        let decoded = try JSONDecoder().decode(Shortcut.self, from: JSONEncoder().encode(shortcut))
        #expect(decoded == shortcut)
    }
}
