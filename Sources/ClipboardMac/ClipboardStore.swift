import AppKit
import Combine
import ClipboardCore

@MainActor
public final class ClipboardStore: ObservableObject {
    @Published public private(set) var history = History()
    @Published public var isPaused = false
    @Published public var notice: String?
    public var onHistoryChange: (([Clip]) -> Void)?
    private let pasteboard: NSPasteboard
    private var timer: Timer?
    private var lastChange: Int

    public init(pasteboard: NSPasteboard = .general, limit: Int = 25) {
        self.pasteboard = pasteboard
        lastChange = pasteboard.changeCount
        history.setLimit(limit)
    }
    public func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.captureClipboard() }
        }
        timer?.tolerance = 0.1
    }
    public func stop() { timer?.invalidate(); timer = nil }
    public func setLimit(_ limit: Int) { history.setLimit(limit); onHistoryChange?(history.clips) }
    public func remove(_ id: UUID) { history.remove(id); onHistoryChange?(history.clips) }
    public func clear() { history.clear(); onHistoryChange?(history.clips) }
    public func insert(_ clip: Clip) { history.insert(clip); onHistoryChange?(history.clips) }
    public func copy(_ clip: Clip) -> Bool {
        let succeeded = ClipboardCodec.write(clip, to: pasteboard)
        lastChange = pasteboard.changeCount
        if !succeeded { notice = "Could not copy this item. Try again." }
        return succeeded
    }
    public func captureClipboard() {
        guard pasteboard.changeCount != lastChange else { return }
        lastChange = pasteboard.changeCount
        guard !isPaused, let clip = ClipboardCodec.read(from: pasteboard, byteLimit: history.byteLimit) else { return }
        insert(clip)
    }
}
