import Testing
@testable import ClipboardCore

struct PastePolicyTests {
    @Test(arguments: ["AXTextField", "AXTextArea", "AXSearchField", "AXComboBox"])
    func acceptsEditableInputs(_ role: String) {
        #expect(PasteTargetState(role: role, isEnabled: true, isEditable: true, isSecure: false).canPaste)
    }
    @Test(arguments: ["AXButton", "AXStaticText", "AXWebArea", "AXWindow", "", "AXSecureTextField"])
    func rejectsNonInputs(_ role: String) {
        #expect(!PasteTargetState(role: role, isEnabled: true, isEditable: true, isSecure: false).canPaste)
    }
    @Test func rejectsDisabledReadOnlyAndSecureFields() {
        #expect(!PasteTargetState(role: "AXTextField", isEnabled: false, isEditable: true, isSecure: false).canPaste)
        #expect(!PasteTargetState(role: "AXTextField", isEnabled: true, isEditable: false, isSecure: false).canPaste)
        #expect(!PasteTargetState(role: "AXTextField", isEnabled: true, isEditable: true, isSecure: true).canPaste)
    }
}
