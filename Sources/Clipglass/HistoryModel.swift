import AppKit
import Combine
import ClipboardCore
import ClipboardMac

@MainActor
final class HistoryModel: ObservableObject {
    let store: ClipboardStore
    let settings: AppSettings
    @Published var query = "" { didSet { selection = 0 } }
    @Published var filter: ClipFilter = .all { didSet { selection = 0 } }
    @Published var selection = 0
    @Published var showsSettings = false
    @Published var isRecordingShortcut = false
    @Published var shortcutError: String?
    @Published var destinationName: String?
    @Published var hasPermission = PasteService.hasPermission
    @Published var isBusy = false
    @Published var isLoaded = false
    var choose: ((Clip, Bool) -> Void)?
    var dismiss: (() -> Void)?
    var saveShortcut: ((Shortcut) -> Bool)?
    private var subscriptions = Set<AnyCancellable>()

    init(store: ClipboardStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
        store.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        settings.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
    }
    var clips: [Clip] { ClipSearch.results(in: store.history.clips, query: query, filter: filter) }
    var selected: Clip? { clips.indices.contains(selection) ? clips[selection] : clips.first }
    var destinationLabel: String {
        if !settings.autoPaste { return "Copy to clipboard" }
        if !hasPermission { return "Enable direct paste in Settings" }
        return destinationName.map { "Paste to \($0)" } ?? "No editable field selected"
    }
    func handle(_ event: NSEvent) -> Bool {
        if isRecordingShortcut { return record(event) }
        if event.keyCode == 53 { dismiss?(); return true }
        let modifiers = ShortcutModifiers(eventFlags: event.modifierFlags)
        if modifiers == .command, event.charactersIgnoringModifiers == "," { showsSettings.toggle(); return true }
        guard !showsSettings, !isBusy, isLoaded else { return false }
        if modifiers == settings.quickModifiers.modifiers,
           let number = Int(event.charactersIgnoringModifiers ?? ""), (1...9).contains(number), clips.indices.contains(number - 1) {
            choose?(clips[number - 1], false); return true
        }
        if event.keyCode == 36, let selected { choose?(selected, modifiers == .command); return true }
        guard modifiers.isEmpty else { return false }
        if event.keyCode == 125 { selection = min(selection + 1, max(0, clips.count - 1)); return true }
        if event.keyCode == 126 { selection = max(0, selection - 1); return true }
        return false
    }
    private func record(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 { isRecordingShortcut = false; return true }
        let special: [UInt16: String] = [49: "Space", 122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6"]
        let label = special[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
        let shortcut = Shortcut(keyCode: UInt32(event.keyCode), modifiers: .init(eventFlags: event.modifierFlags), keyLabel: label)
        guard shortcut.isValid, !shortcut.isReserved else {
            shortcutError = "Use ⌘, ⌃, or ⌥ with a key. Common editing shortcuts are reserved."
            return true
        }
        guard saveShortcut?(shortcut) == true else { shortcutError = "That shortcut is unavailable. Try another."; return true }
        shortcutError = nil
        isRecordingShortcut = false
        return true
    }
}
