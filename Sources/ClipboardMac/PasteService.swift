import AppKit
@preconcurrency import ApplicationServices

@MainActor
public enum PasteService {
    public static var hasPermission: Bool { AXIsProcessTrusted() }

    @discardableResult public static func requestPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        return openPermissionSettings { NSWorkspace.shared.open($0) }
    }

    /// Open Settings explicitly because macOS may suppress a previously dismissed prompt.
    public static func openPermissionSettings(open: (URL) -> Bool) -> Bool {
        let destinations = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
        ]
        for address in destinations {
            if let url = URL(string: address), open(url) { return true }
        }
        return false
    }

    /// Wait for app focus and released shortcut keys, then recheck the original editable element.
    public static func paste(to destination: PasteDestination, copy: () -> Bool) async -> Bool {
        guard hasPermission, destination.isStillEditable(), destination.application.activate() else { return false }
        for _ in 0..<40 {
            try? await Task.sleep(for: .milliseconds(20))
            guard !Task.isCancelled else { return false }
            let isFrontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier == destination.application.processIdentifier
            let flags = CGEventSource.flagsState(.combinedSessionState)
            let heldModifiers = flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift])
            guard isFrontmost, heldModifiers.isEmpty else { continue }
            guard destination.isStillEditable(), copy() else { return false }
            return postPaste(pid: destination.application.processIdentifier)
        }
        return false
    }
    private static func postPaste(pid: pid_t) -> Bool {
        guard let source = CGEventSource(stateID: .privateState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return false }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.postToPid(pid)
        up.postToPid(pid)
        return true
    }
}
