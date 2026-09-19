import Foundation

public enum ClipFilter: String, CaseIterable, Sendable {
    case all = "All", text = "Text", images = "Images", files = "Files"
    public func includes(_ kind: String) -> Bool {
        switch self {
        case .all: true
        case .text: kind == "Text" || kind == "Link"
        case .images: kind == "Image"
        case .files: kind == "File"
        }
    }
}

public enum ClipSearch {
    public static func results(in clips: [Clip], query: String, filter: ClipFilter) -> [Clip] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        return clips.filter { clip in
            filter.includes(clip.kind) && words.allSatisfy {
                (clip.title + " " + clip.kind).localizedStandardContains($0)
            }
        }
    }
}
