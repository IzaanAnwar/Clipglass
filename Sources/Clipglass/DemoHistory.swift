import AppKit
import ClipboardCore
import ClipboardMac

@MainActor
enum DemoHistory {
    static func populate(_ store: ClipboardStore) {
        let examples = [
            ("Text", "The details make the difference."),
            ("Link", "https://developer.apple.com/design/"),
            ("Text", "Meeting notes\n\nKeep the interface quiet. Give the content room.\n\n• Review keyboard shortcuts\n• Test light and dark mode\n• Ship the small improvements"),
            ("Text", "swift build -c release"),
            ("Text", "See you at 10:30 tomorrow."),
            ("Text", "A place for everything you copy.")
        ]
        for (kind, title) in examples.reversed() {
            store.insert(Clip(title: title, kind: kind, payloads: [[NSPasteboard.PasteboardType.string.rawValue: Data(title.utf8)]]))
        }
    }
}
