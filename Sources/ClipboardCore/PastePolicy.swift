/// Paste only when the destination explicitly exposes a writable, enabled text input.
public struct PasteTargetState: Sendable {
    public let role: String
    public let isEnabled: Bool
    public let isEditable: Bool
    public let isSecure: Bool
    public init(role: String, isEnabled: Bool, isEditable: Bool, isSecure: Bool) {
        self.role = role
        self.isEnabled = isEnabled
        self.isEditable = isEditable
        self.isSecure = isSecure
    }
    public var canPaste: Bool {
        ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"].contains(role)
            && isEnabled && isEditable && !isSecure
    }
}
