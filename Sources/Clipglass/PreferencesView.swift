import SwiftUI
import ClipboardCore
import ClipboardMac

struct PreferencesView: View {
    @ObservedObject var model: HistoryModel
    @ViewState<String> private var limit = ""
    @ViewState<Bool> private var confirmsClear = false
    var body: some View {
        Form {
            Section("Keyboard") {
                LabeledContent("Open Clipglass") {
                    Button(model.isRecordingShortcut ? "Press shortcut…" : model.settings.openShortcut.display) {
                        model.isRecordingShortcut.toggle(); model.shortcutError = nil
                    }.buttonStyle(.bordered).help("Click, then press your preferred combination. Escape cancels.")
                    Button("Reset") { _ = model.saveShortcut?(.defaultOpen) }.buttonStyle(.borderless)
                }
                if let error = model.shortcutError { Text(error).font(.caption).foregroundStyle(.orange) }
                Picker("Paste items 1–9", selection: Binding(get: { model.settings.quickModifiers }, set: { model.settings.quickModifiers = $0 })) {
                    ForEach(QuickModifiers.allCases, id: \.self) { Text($0.display).tag($0) }
                }
                Text("Number shortcuts work inside Clipglass. Return pastes the selection; ⌘Return copies only.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Pasting") {
                Toggle("Paste directly into the previous app", isOn: Binding(get: { model.settings.autoPaste }, set: { model.settings.autoPaste = $0 }))
                HStack {
                    Label(model.hasPermission ? "Accessibility enabled" : "Accessibility permission needed", systemImage: model.hasPermission ? "checkmark.circle" : "hand.raised")
                    Spacer()
                    Button(model.hasPermission ? "Check again" : "Enable…") {
                        PasteService.requestPermission()
                        model.hasPermission = PasteService.hasPermission
                    }
                }
                Text("Pastes only into an editable field. Secure fields, read-only views, and unsupported apps are left alone.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("History") {
                HStack {
                    Text("Saved items")
                    Spacer()
                    TextField("25", text: $limit).frame(width: 75).multilineTextAlignment(.trailing)
                    Button("Apply") { if let count = Int(limit) { model.settings.setLimit(count); model.store.setLimit(count) } }
                        .disabled(Int(limit).map { !(1...10_000).contains($0) } ?? true)
                }
                Toggle("Pause capture", isOn: Binding(get: { model.store.isPaused }, set: { model.store.isPaused = $0 }))
                Text("1–10,000 items, up to 128 MB. Saved locally across restarts. Confidential items marked by their source app are skipped.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Clear saved history…", role: .destructive) { confirmsClear = true }.disabled(!model.isLoaded)
                    Spacer()
                    Button("Quit Clipglass") { NSApp.terminate(nil) }
                }
            }
        }.formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .onAppear { limit = String(model.settings.historyLimit) }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in model.hasPermission = PasteService.hasPermission }
        .confirmationDialog("Delete all saved clipboard items?", isPresented: $confirmsClear) {
            Button("Delete saved history", role: .destructive) { model.store.clear() }
        } message: { Text("This removes the local history. Your current system clipboard is unchanged.") }
    }
}
