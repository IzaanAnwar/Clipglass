import Carbon
import AppKit
import ClipboardCore

@MainActor
public final class GlobalShortcut {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    public var onPress: (() -> Void)?
    public init() {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            MainActor.assumeIsolated {
                Unmanaged<GlobalShortcut>.fromOpaque(context).takeUnretainedValue().onPress?()
            }
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }
    public func register(_ shortcut: Shortcut) -> Bool {
        guard shortcut.isValid, !shortcut.isReserved, handler != nil else { return false }
        var replacement: EventHotKeyRef?
        let identifier = EventHotKeyID(signature: 0x434C4950, id: 1)
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers.carbonFlags, identifier,
                                        GetApplicationEventTarget(), 0, &replacement)
        guard status == noErr else { return false }
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = replacement
        return true
    }
    public func stop() {
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        if let handler { RemoveEventHandler(handler); self.handler = nil }
    }
}

extension ShortcutModifiers {
    public init(eventFlags: NSEvent.ModifierFlags) {
        self.init(rawValue: 0)
        if eventFlags.contains(.command) { insert(.command) }
        if eventFlags.contains(.option) { insert(.option) }
        if eventFlags.contains(.control) { insert(.control) }
        if eventFlags.contains(.shift) { insert(.shift) }
    }
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        return flags
    }
}
