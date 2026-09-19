import SwiftUI
import ClipboardCore

struct ClipPreview: View {
    let clip: Clip?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let clip {
                HStack {
                    Text("Preview").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: clip.symbol).foregroundStyle(.tertiary)
                }
                ScrollView {
                    if let image = clip.previewImage {
                        Image(nsImage: image).resizable().scaledToFit().clipShape(.rect(cornerRadius: 8))
                    } else {
                        Text(String(clip.title.prefix(20_000)))
                            .font(.system(size: 13)).lineSpacing(4).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 5) {
                    Text(clip.createdAt.formatted(date: .abbreviated, time: .shortened))
                    Text("\(clip.kind) · \(ByteCountFormatter.string(fromByteCount: Int64(clip.byteCount), countStyle: .file))")
                }.font(.system(size: 10)).foregroundStyle(.secondary)
            } else {
                Spacer()
                Image(systemName: "doc.on.clipboard").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Text("A little less copying.\nA little more doing.").font(.system(size: 13)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                Spacer()
            }
        }.padding(20).background(.primary.opacity(0.025))
    }
}
