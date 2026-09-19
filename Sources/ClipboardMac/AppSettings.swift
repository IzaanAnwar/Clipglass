import Combine
import Foundation
import ClipboardCore

@MainActor
public final class AppSettings: ObservableObject {
    @Published public private(set) var openShortcut: Shortcut
    @Published public var quickModifiers: QuickModifiers { didSet { defaults.set(quickModifiers.rawValue, forKey: "quickModifiers") } }
    @Published public var autoPaste: Bool { didSet { defaults.set(autoPaste, forKey: "autoPaste") } }
    @Published public private(set) var historyLimit: Int
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let bytes = defaults.data(forKey: "openShortcut"),
           let saved = try? JSONDecoder().decode(Shortcut.self, from: bytes), saved.isValid, !saved.isReserved {
            openShortcut = saved
        } else {
            openShortcut = .defaultOpen
        }
        quickModifiers = QuickModifiers(rawValue: defaults.string(forKey: "quickModifiers") ?? "") ?? .command
        autoPaste = defaults.object(forKey: "autoPaste") as? Bool ?? true
        historyLimit = min(max(defaults.object(forKey: "historyLimit") as? Int ?? 25, 1), 10_000)
    }

    public func saveShortcut(_ shortcut: Shortcut) {
        guard shortcut.isValid, !shortcut.isReserved, let bytes = try? JSONEncoder().encode(shortcut) else { return }
        defaults.set(bytes, forKey: "openShortcut")
        openShortcut = shortcut
    }

    public func setLimit(_ limit: Int) {
        historyLimit = min(max(limit, 1), 10_000)
        defaults.set(historyLimit, forKey: "historyLimit")
    }
}
