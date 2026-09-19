import Foundation

public struct ShortcutModifiers: OptionSet, Codable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let command = Self(rawValue: 1 << 0)
    public static let option = Self(rawValue: 1 << 1)
    public static let control = Self(rawValue: 1 << 2)
    public static let shift = Self(rawValue: 1 << 3)
    public var symbols: String {
        [(Self.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
            .filter { contains($0.0) }.map(\.1).joined()
    }
}

public struct Shortcut: Codable, Equatable, Sendable {
    public let keyCode: UInt32
    public let modifiers: ShortcutModifiers
    public let keyLabel: String
    public init(keyCode: UInt32, modifiers: ShortcutModifiers, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyLabel = keyLabel
    }
    public static let defaultOpen = Self(keyCode: 9, modifiers: [.control, .option], keyLabel: "V")
    public var display: String { modifiers.symbols + keyLabel }
    public var isValid: Bool {
        keyCode < 128 && !keyLabel.isEmpty && ![53, 36, 48, 51, 123, 124, 125, 126].contains(keyCode)
            && !modifiers.intersection([.command, .control, .option]).isEmpty
            && modifiers.subtracting([.command, .control, .option, .shift]).isEmpty
    }
    public var isReserved: Bool {
        let systemKeys: [UInt32] = [0, 6, 7, 8, 9, 12, 13, 46, 48, 49]
        return modifiers == .command && systemKeys.contains(keyCode)
    }
}

public enum QuickModifiers: String, CaseIterable, Codable, Sendable {
    case command, option, controlOption
    public var modifiers: ShortcutModifiers {
        switch self {
        case .command: .command
        case .option: .option
        case .controlOption: [.control, .option]
        }
    }
    public var display: String { modifiers.symbols + "1–9" }
}
