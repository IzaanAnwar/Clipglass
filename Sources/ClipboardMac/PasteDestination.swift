import AppKit
import ApplicationServices
import ClipboardCore

@MainActor
public struct PasteDestination {
    public let application: NSRunningApplication
    private let element: AXUIElement
    public var name: String { application.localizedName ?? "previous app" }

    public static func capture(application: NSRunningApplication) -> Self? {
        guard AXIsProcessTrusted(), let element = focusedElement(pid: application.processIdentifier),
              state(of: element).canPaste else { return nil }
        return Self(application: application, element: element)
    }

    public func isStillEditable() -> Bool {
        guard !application.isTerminated, let focused = Self.focusedElement(pid: application.processIdentifier) else { return false }
        return CFEqual(focused, element) && Self.state(of: focused).canPaste
    }

    private static func focusedElement(pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.2)
        guard let value = attribute(kAXFocusedUIElementAttribute, of: app), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
    private static func state(of element: AXUIElement) -> PasteTargetState {
        let role = attribute(kAXRoleAttribute, of: element) as? String ?? ""
        let subrole = attribute(kAXSubroleAttribute, of: element) as? String ?? ""
        let enabled = attribute(kAXEnabledAttribute, of: element) as? Bool ?? false
        let editable = attribute("AXEditable", of: element) as? Bool ?? false
        var valueSettable: DarwinBoolean = false
        var textSettable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &valueSettable)
        AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &textSettable)
        return PasteTargetState(role: role, isEnabled: enabled,
                               isEditable: editable || valueSettable.boolValue || textSettable.boolValue,
                               isSecure: subrole == kAXSecureTextFieldSubrole || role == kAXSecureTextFieldSubrole)
    }
    private static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
}
