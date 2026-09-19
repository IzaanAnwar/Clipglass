import SwiftUI

@main
struct ClipglassApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        Settings { EmptyView() }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button("Settings…") { delegate.showPreferences() }.keyboardShortcut(",")
                }
            }
    }
}
