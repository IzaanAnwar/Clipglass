import Foundation
import ClipboardCore
import ClipboardMac

@MainActor
final class HistoryPersistence {
    private let database: HistoryDatabase
    private var revision = 0
    private var pending: Task<Bool, Never>?
    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        database = HistoryDatabase(url: base.appendingPathComponent("Clipglass/history.sqlite"))
    }
    func restore(into store: ClipboardStore) async -> Bool {
        do {
            for clip in try await database.load().reversed() { store.insert(clip) }
            store.onHistoryChange = { [weak self, weak store] clips in self?.save(clips, store: store) }
            save(store.history.clips, store: store)
            return true
        } catch {
            store.notice = "History could not be opened. \(error.localizedDescription) Quit and check the database before continuing."
            return false
        }
    }
    func flush() async -> Bool { await pending?.value ?? true }
    private func save(_ clips: [Clip], store: ClipboardStore?) {
        revision += 1
        let version = revision
        let previous = pending
        pending = Task { [database, weak store] in
            _ = await previous?.value
            do { try await database.save(clips, revision: version); return true }
            catch { store?.notice = "History could not be saved. \(error.localizedDescription)"; return false }
        }
    }
}
