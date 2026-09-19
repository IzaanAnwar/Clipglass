import Foundation
import Testing
import ClipboardCore
@testable import ClipboardMac

@MainActor
struct SettingsTests {
    @Test func preferencesSurviveNewInstance() throws {
        let suite = "Clipglass.tests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.historyLimit == 25)
        #expect(settings.autoPaste)
        settings.setLimit(100)
        settings.quickModifiers = .controlOption
        settings.autoPaste = false
        let shortcut = Shortcut(keyCode: 40, modifiers: [.command, .shift], keyLabel: "K")
        settings.saveShortcut(shortcut)
        let restored = AppSettings(defaults: defaults)
        #expect(restored.historyLimit == 100)
        #expect(restored.quickModifiers == .controlOption)
        #expect(!restored.autoPaste)
        #expect(restored.openShortcut == shortcut)
    }
    @Test func invalidSavedShortcutFallsBack() throws {
        let suite = "Clipglass.tests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("broken".utf8), forKey: "openShortcut")
        defaults.set(-2, forKey: "historyLimit")
        let settings = AppSettings(defaults: defaults)
        #expect(settings.openShortcut == .defaultOpen)
        #expect(settings.historyLimit == 1)
    }
}
