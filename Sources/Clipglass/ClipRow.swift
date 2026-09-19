import SwiftUI
import ClipboardCore

struct ClipRow: View {
    let clip: Clip
    let shortcut: String
    let isSelected: Bool
    @ViewState<Bool> private var isHovered = false
    var body: some View {
        HStack(spacing: 11) {
            ClipThumbnail(clip: clip).frame(width: 32, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(clip.title.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 13, weight: .medium)).lineLimit(1)
                HStack(spacing: 5) {
                    Text(clip.kind)
                    Text("·")
                    Text(clip.createdAt, style: .time)
                }.font(.system(size: 11)).opacity(isSelected ? 0.8 : 0.6)
            }
            Spacer(minLength: 4)
            Text(shortcut).font(.system(size: 11, design: .monospaced)).opacity(0.65)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 11).frame(height: 61)
        .background(isSelected ? Color.accentColor : isHovered ? Color.primary.opacity(0.05) : .clear, in: .rect(cornerRadius: 10))
        .contentShape(.rect(cornerRadius: 10))
        .onHover { isHovered = $0 }
        .accessibilityLabel("\(clip.kind): \(clip.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ClipThumbnail: View {
    let clip: Clip
    var body: some View {
        if let image = clip.previewImage {
            Image(nsImage: image).resizable().scaledToFill().frame(width: 30, height: 30).clipShape(.rect(cornerRadius: 5))
        } else {
            Image(systemName: clip.symbol).font(.system(size: 21, weight: .light))
        }
    }
}

extension Clip {
    var symbol: String {
        switch kind {
        case "Image": "photo"
        case "File": "doc"
        case "Link": "link"
        default: "doc.text"
        }
    }
    var previewImage: NSImage? {
        guard kind == "Image", let first = payloads.first,
              let bytes = first[NSPasteboard.PasteboardType.png.rawValue] ?? first[NSPasteboard.PasteboardType.tiff.rawValue] else { return nil }
        return NSImage(data: bytes)
    }
}
