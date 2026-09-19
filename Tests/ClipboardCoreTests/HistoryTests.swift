import Foundation
import Testing
@testable import ClipboardCore
struct HistoryTests {
    private func clip(_ title: String, size: Int = 1) -> Clip {
        Clip(title: title, kind: "Text", payloads: [[title: Data(repeating: 1, count: size)]])
    }
    @Test func defaultLimitEvictsOldest() {
        var history = History()
        for index in 0..<30 { history.insert(clip(String(index))) }
        #expect(history.clips.count == 25)
        #expect(history.clips.first?.title == "29")
        #expect(history.clips.last?.title == "5")
    }
    @Test func duplicatesMoveToFront() {
        var history = History()
        history.insert(clip("a")); history.insert(clip("b")); history.insert(clip("a"))
        #expect(history.clips.map(\.title) == ["a", "b"])
    }
    @Test func shrinkingAndExpandingLimits() {
        var history = History()
        history.setLimit(100)
        for index in 0..<100 { history.insert(clip(String(index))) }
        #expect(history.clips.count == 100)
        history.setLimit(2)
        #expect(history.clips.map(\.title) == ["99", "98"])
        history.setLimit(-1)
        #expect(history.limit == 1)
        history.setLimit(Int.max)
        #expect(history.limit == 10_000)
    }
    @Test func memoryBudgetAndOversizedItems() {
        var history = History(byteLimit: 5)
        history.insert(clip("a", size: 3)); history.insert(clip("b", size: 3))
        #expect(history.clips.map(\.title) == ["b"])
        history.insert(clip("large", size: 6))
        #expect(history.clips.map(\.title) == ["b"])
    }
    @Test func removeAndClear() {
        var history = History()
        let first = clip("a")
        history.insert(first); history.insert(clip("b"))
        history.remove(first.id)
        #expect(history.clips.count == 1)
        history.clear()
        #expect(history.clips.isEmpty)
    }
}
