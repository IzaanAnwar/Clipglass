import AppKit
import SwiftUI
import ClipboardCore
import ClipboardMac

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let settings = AppSettings(defaults: ProcessInfo.processInfo.arguments.contains("--demo") ? UserDefaults(suiteName: "Clipglass.Demo")! : .standard)
    private lazy var store = ClipboardStore(limit: settings.historyLimit)
    private lazy var model = HistoryModel(store: store, settings: settings)
    private let shortcut = GlobalShortcut()
    private let persistence = HistoryPersistence()
    private var statusItem: NSStatusItem?
    private var panel: ClipboardPanel?
    private var keyMonitor: Any?
    private var outsideClickMonitor: Any?
    private var appSwitchObserver: NSObjectProtocol?
    private var previousApp: NSRunningApplication?
    private var destination: PasteDestination?
    private var pasteTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureActions()
        configureStatusItem()
        shortcut.onPress = { [weak self] in self?.togglePanel() }
        if !ProcessInfo.processInfo.arguments.contains("--demo"), !shortcut.register(settings.openShortcut) { store.notice = "Open shortcut unavailable. Set another in Settings." }
        let isDemo = ProcessInfo.processInfo.arguments.contains("--demo")
        Task {
            if isDemo { DemoHistory.populate(store) }
            else { guard await persistence.restore(into: store) else { showPanel(); return }; store.start() }
            model.isLoaded = true
            showPanel()
        }
    }
    private func configureActions() {
        model.dismiss = { [weak self] in self?.dismissPanel() }
        model.choose = { [weak self] clip, copyOnly in self?.select(clip, copyOnly: copyOnly) }
        model.saveShortcut = { [weak self] proposed in
            guard let self else { return false }
            if proposed == settings.openShortcut { return true }
            guard shortcut.register(proposed) else { return false }
            settings.saveShortcut(proposed)
            return true
        }
    }
    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipglass")
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        item.button?.toolTip = "Clipglass"
        statusItem = item
    }
    func showPreferences() {
        if panel?.isVisible != true { showPanel() }
        model.showsSettings = true
    }
    @objc private func togglePanel() {
        guard !model.isBusy else { return }
        if panel?.isVisible == true { dismissPanel() } else { showPanel() }
    }
    private func showPanel() {
        guard panel == nil else { return }
        previousApp = NSWorkspace.shared.frontmostApplication
        if previousApp?.processIdentifier == ProcessInfo.processInfo.processIdentifier { previousApp = nil }
        destination = previousApp.flatMap { PasteDestination.capture(application: $0) }
        model.destinationName = destination?.name
        model.hasPermission = PasteService.hasPermission
        model.query = ""
        model.selection = 0
        model.showsSettings = false
        let window = ClipboardPanel(model: model)
        panel = window
        window.delegate = self
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismissPanel(restoreFocus: false)
        }
        appSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.dismissPanel(restoreFocus: false) }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel?.isKeyWindow == true else { return event }
            return self.model.handle(event) ? nil : event
        }
        window.makeKeyAndOrderFront(nil)
    }
    func windowDidResignKey(_ notification: Notification) {
        dismissPanel(restoreFocus: false)
    }
    private func dismissPanel(restoreFocus: Bool = true) {
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor); self.outsideClickMonitor = nil }
        if let appSwitchObserver { NSWorkspace.shared.notificationCenter.removeObserver(appSwitchObserver); self.appSwitchObserver = nil }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor); self.keyMonitor = nil }
        model.isRecordingShortcut = false
        panel?.delegate = nil
        panel?.orderOut(nil)
        panel?.contentView = nil
        panel = nil
        if restoreFocus { previousApp?.activate() }
    }
    private func select(_ clip: Clip, copyOnly: Bool) {
        guard !model.isBusy else { return }
        if copyOnly || !settings.autoPaste {
            if store.copy(clip) { dismissPanel() }
            return
        }
        guard PasteService.hasPermission else {
            model.showsSettings = true
            store.notice = "Enable Accessibility to paste directly, or use ⌘Return to copy only."
            return
        }
        guard let destination, destination.isStillEditable() else {
            store.notice = "Nothing pasted. Focus an editable text field, then reopen Clipglass."
            return
        }
        model.isBusy = true
        dismissPanel(restoreFocus: false)
        pasteTask = Task { [weak self] in
            guard let self else { return }
            let pasted = await PasteService.paste(to: destination) { self.store.copy(clip) }
            if !pasted { store.notice = "Nothing pasted because the destination or focus changed." }
            model.isBusy = false
        }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows { showPanel() }
        return true
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        store.stop()
        pasteTask?.cancel()
        Task {
            let saved = await persistence.flush()
            if saved { shortcut.stop() } else { store.start(); showPreferences() }
            sender.reply(toApplicationShouldTerminate: saved)
        }
        return .terminateLater
    }
}
