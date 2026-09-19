import Foundation
import CSQLite
import ClipboardCore

public struct HistoryDatabaseError: Error, LocalizedError, Sendable {
    public let message: String
    public var errorDescription: String? { message }
}

/// An actor confines SQLite operations to one executor; transactions preserve the last complete history.
public actor HistoryDatabase {
    private let url: URL
    private var latestRevision = 0
    public init(url: URL) { self.url = url }

    public func load() throws -> [Clip] {
        let database = try open()
        defer { sqlite3_close(database) }
        let statement = try prepare("SELECT payload FROM clips ORDER BY position DESC LIMIT 10000", in: database)
        defer { sqlite3_finalize(statement) }
        var clips: [Clip] = []
        var bytes = 0
        var status = sqlite3_step(statement)
        while status == SQLITE_ROW {
            let count = Int(sqlite3_column_bytes(statement, 0))
            guard count <= 180 * 1_024 * 1_024, let pointer = sqlite3_column_blob(statement, 0) else {
                throw HistoryDatabaseError(message: "Invalid clipboard record.")
            }
            let clip = try JSONDecoder().decode(Clip.self, from: Data(bytes: pointer, count: count))
            bytes += clip.byteCount
            if bytes <= 128 * 1_024 * 1_024 { clips.append(clip) }
            status = sqlite3_step(statement)
        }
        guard status == SQLITE_DONE else { throw failure(database) }
        return clips
    }

    public func save(_ clips: [Clip], revision: Int) throws {
        guard revision > latestRevision else { return }
        let database = try open()
        defer { sqlite3_close(database) }
        try execute("BEGIN IMMEDIATE", in: database)
        do {
            try execute("UPDATE clips SET position = -1", in: database)
            for (index, clip) in clips.enumerated() {
                try upsert(clip, position: clips.count - index, in: database)
            }
            try execute("DELETE FROM clips WHERE position = -1", in: database)
            try execute("COMMIT", in: database)
            latestRevision = revision
            // Remove old pages from the WAL after deletion as well as updating the main database.
            try execute("PRAGMA wal_checkpoint(TRUNCATE)", in: database)
        } catch {
            try? execute("ROLLBACK", in: database)
            throw error
        }
    }

    private func open() throws -> OpaquePointer {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                               attributes: [.posixPermissions: 0o700])
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
                throw HistoryDatabaseError(message: "Could not create clipboard database.")
            }
        }
        var handle: OpaquePointer?
        guard sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK,
              let database = handle else {
            if let handle { sqlite3_close(handle) }
            throw HistoryDatabaseError(message: "Could not open clipboard database.")
        }
        do {
            sqlite3_busy_timeout(database, 3_000)
            try execute("PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA secure_delete=ON", in: database)
            try execute("CREATE TABLE IF NOT EXISTS clips (id TEXT PRIMARY KEY, position INTEGER NOT NULL, payload BLOB NOT NULL)", in: database)
            return database
        } catch { sqlite3_close(database); throw error }
    }

    private func upsert(_ clip: Clip, position: Int, in database: OpaquePointer) throws {
        let sql = "INSERT INTO clips(id, position, payload) VALUES(?, ?, ?) ON CONFLICT(id) DO UPDATE SET position=excluded.position"
        let statement = try prepare(sql, in: database)
        defer { sqlite3_finalize(statement) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let payload = try JSONEncoder().encode(clip)
        sqlite3_bind_text(statement, 1, clip.id.uuidString, -1, transient)
        sqlite3_bind_int64(statement, 2, Int64(position))
        _ = payload.withUnsafeBytes { sqlite3_bind_blob(statement, 3, $0.baseAddress, Int32($0.count), transient) }
        guard sqlite3_step(statement) == SQLITE_DONE else { throw failure(database) }
    }
    private func execute(_ sql: String, in database: OpaquePointer) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else { throw failure(database) }
    }
    private func prepare(_ sql: String, in database: OpaquePointer) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else { throw failure(database) }
        return statement
    }
    private func failure(_ database: OpaquePointer) -> HistoryDatabaseError {
        HistoryDatabaseError(message: "Clipboard database: " + String(cString: sqlite3_errmsg(database)))
    }
}
