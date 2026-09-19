import Foundation
public struct Clip: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let kind: String
    public let payloads: [[String: Data]]
    public let createdAt: Date
    public var byteCount: Int { payloads.flatMap(\.values).reduce(0) { $0 + $1.count } }
    public init(title: String, kind: String, payloads: [[String: Data]]) {
        id = UUID()
        createdAt = Date()
        self.title = title
        self.kind = kind
        self.payloads = payloads
    }
}
public struct History: Sendable {
    public private(set) var clips: [Clip] = []
    public private(set) var limit = 25
    public let byteLimit: Int
    public init(byteLimit: Int = 128 * 1_024 * 1_024) { self.byteLimit = byteLimit }
    public mutating func setLimit(_ value: Int) {
        limit = min(max(value, 1), 10_000)
        trim()
    }
    public mutating func insert(_ clip: Clip) {
        guard clip.byteCount <= byteLimit, !clip.payloads.isEmpty else { return }
        clips.removeAll { $0.payloads == clip.payloads }
        clips.insert(clip, at: 0)
        trim()
    }
    public mutating func remove(_ id: UUID) { clips.removeAll { $0.id == id } }
    public mutating func clear() { clips.removeAll() }
    private mutating func trim() {
        var total = 0
        clips = Array(clips.prefix(limit).prefix { clip in
            total += clip.byteCount
            return total <= byteLimit
        })
    }
}
