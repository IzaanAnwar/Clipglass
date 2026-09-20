import Foundation
import Testing
@testable import ClipboardMac

@MainActor
struct PermissionSettingsTests {
    @Test func opensAccessibilityPaneFirst() {
        var visited: [String] = []
        let opened = PasteService.openPermissionSettings { url in
            visited.append(url.absoluteString)
            return true
        }
        #expect(opened)
        #expect(visited == ["x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"])
    }
    @Test func fallsBackToPrivacySettings() {
        var visited: [URL] = []
        let opened = PasteService.openPermissionSettings { url in
            visited.append(url)
            return visited.count == 2
        }
        #expect(opened)
        #expect(visited.count == 2)
        #expect(visited.last?.absoluteString == "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")
    }
    @Test func reportsFailureWhenNeitherDestinationOpens() {
        #expect(!PasteService.openPermissionSettings { _ in false })
    }
}
