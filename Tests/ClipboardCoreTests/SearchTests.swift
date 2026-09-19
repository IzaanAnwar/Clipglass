import Foundation
import Testing
@testable import ClipboardCore

struct SearchTests {
    let clips = [
        Clip(title: "Hello world", kind: "Text", payloads: [["text": Data([1])]]),
        Clip(title: "https://example.com", kind: "Link", payloads: [["text": Data([2])]]),
        Clip(title: "Copied image", kind: "Image", payloads: [["image": Data([3])]])
    ]
    @Test func matchesAllWordsCaseInsensitively() {
        #expect(ClipSearch.results(in: clips, query: "  WORLD hello ", filter: .all).count == 1)
        #expect(ClipSearch.results(in: clips, query: "world missing", filter: .all).isEmpty)
    }
    @Test func combinesFiltersWithSearch() {
        #expect(ClipSearch.results(in: clips, query: "", filter: .text).count == 2)
        #expect(ClipSearch.results(in: clips, query: "hello", filter: .images).isEmpty)
        #expect(ClipSearch.results(in: clips, query: "", filter: .images).count == 1)
    }
}
