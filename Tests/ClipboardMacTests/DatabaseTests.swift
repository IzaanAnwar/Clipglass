import Foundation
import Testing
import ClipboardCore
@testable import ClipboardMac

struct DatabaseTests {
    private func clip(_ title: String) -> Clip { Clip(title: title, kind: "Text", payloads: [["public.utf8-plain-text": Data(title.utf8)]]) }
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Clipglass.tests.\(UUID())")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    @Test func survivesReopenWithOrderAndIdentity() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("history.sqlite")
        let original = [clip("newest"), clip("older")]
        try await HistoryDatabase(url: url).save(original, revision: 1)
        let loaded = try await HistoryDatabase(url: url).load()
        #expect(loaded == original)
        #expect((try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int) == 0o600)
    }
    @Test func deletionAndClearPersist() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("history.sqlite")
        let database = HistoryDatabase(url: url)
        let original = [clip("a"), clip("b")]
        try await database.save(original, revision: 1)
        try await database.save([original[1]], revision: 2)
        #expect(try await HistoryDatabase(url: url).load() == [original[1]])
        try await database.save([], revision: 3)
        #expect(try await HistoryDatabase(url: url).load().isEmpty)
    }
    @Test func staleSavesCannotOverwriteLatestHistory() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = HistoryDatabase(url: directory.appendingPathComponent("history.sqlite"))
        let latest = [clip("new")]
        try await database.save(latest, revision: 2)
        try await database.save([clip("old")], revision: 1)
        #expect(try await database.load() == latest)
    }
    @Test func corruptDatabaseIsReportedWithoutReplacement() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("history.sqlite")
        let bytes = Data("not a sqlite database".utf8)
        try bytes.write(to: url)
        await #expect(throws: (any Error).self) { try await HistoryDatabase(url: url).load() }
        #expect(try Data(contentsOf: url) == bytes)
    }
}
