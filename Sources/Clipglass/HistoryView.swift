import SwiftUI
import ClipboardCore
import ClipboardMac

struct HistoryView: View {
    @ObservedObject var model: HistoryModel
    @FocusState private var searchFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().opacity(0.55)
            if model.showsSettings {
                PreferencesView(model: model)
            } else {
                filterBar
                HStack(spacing: 0) {
                    historyList.frame(width: 418)
                    Divider().opacity(0.5)
                    ClipPreview(clip: model.selected).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            if let notice = model.store.notice {
                HStack {
                    Text(notice).font(.caption).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button { model.store.notice = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
                }.padding(12).background(.orange.opacity(0.1))
            }
            Divider().opacity(0.5)
            footer
        }
        .frame(width: 740, height: 530)
        .background(PanelMaterial())
        .clipShape(.rect(cornerRadius: 22))
        .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.22), lineWidth: 0.5) }
        .onAppear { searchFocused = true }
        .onChange(of: model.showsSettings) { if !model.showsSettings { searchFocused = true } }
        .onChange(of: model.store.history.clips.count) { model.selection = min(model.selection, max(0, model.clips.count - 1)) }
    }
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: model.showsSettings ? "slider.horizontal.3" : "magnifyingglass")
                .font(.system(size: 21, weight: .regular)).foregroundStyle(.secondary)
            if model.showsSettings {
                Text("Settings").font(.system(size: 23, weight: .medium))
                Spacer()
            } else {
                TextField("Search clipboard", text: $model.query)
                    .font(.system(size: 23)).textFieldStyle(.plain).focused($searchFocused)
                    .accessibilityIdentifier("clipboard-search")
                    .onKeyPress("f", phases: .down) { key in
                        guard key.modifiers == .command else { return .ignored }
                        searchFocused = true; return .handled
                    }
            }
            Button { model.showsSettings.toggle() } label: {
                Image(systemName: model.showsSettings ? "xmark" : "gearshape").font(.system(size: 15))
                    .frame(width: 28, height: 28)
            }.buttonStyle(.glass).buttonBorderShape(.circle)
                .help(model.showsSettings ? "Close settings" : "Settings · ⌘,")
        }.padding(.horizontal, 22).frame(height: 72)
    }
    private var filterBar: some View {
        HStack(spacing: 4) {
            ForEach(ClipFilter.allCases, id: \.self) { filter in
                Button { model.filter = filter } label: {
                    Text(filter.rawValue).font(.system(size: 12, weight: model.filter == filter ? .semibold : .regular))
                        .padding(.horizontal, 13).padding(.vertical, 6)
                        .background(model.filter == filter ? Color.primary.opacity(0.085) : .clear, in: .capsule)
                }.buttonStyle(.plain).foregroundStyle(model.filter == filter ? .primary : .secondary)
            }
            Spacer()
            Text(model.store.isPaused ? "Paused" : "\(model.store.history.clips.count) saved")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }.padding(.horizontal, 16).frame(height: 44)
    }
    private var historyList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if model.clips.isEmpty {
                    ContentUnavailableView(model.isLoaded ? "Nothing here yet" : "Opening history", systemImage: "clipboard",
                                           description: Text(model.query.isEmpty ? "Copied items appear here." : "Try another search."))
                        .frame(height: 290)
                }
                LazyVStack(spacing: 2) {
                    ForEach(Array(model.clips.enumerated()), id: \.element.id) { index, clip in
                        Button { model.choose?(clip, false) } label: {
                            ClipRow(clip: clip, shortcut: index < 9 ? model.settings.quickModifiers.modifiers.symbols + String(index + 1) : "",
                                    isSelected: model.selected?.id == clip.id)
                        }.buttonStyle(.plain).id(index)
                            .contextMenu {
                                Button("Copy without pasting") { model.choose?(clip, true) }
                                Divider()
                                Button("Remove", role: .destructive) { model.store.remove(clip.id) }
                            }
                    }
                }.padding(.horizontal, 10).padding(.bottom, 8)
            }
            .onChange(of: model.selection) {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.15)) { proxy.scrollTo(model.selection) }
            }
        }
    }
    private var footer: some View {
        HStack(spacing: 7) {
            Image(systemName: "clipboard").font(.system(size: 12))
            Text("Clipglass").fontWeight(.medium)
            Text("·").foregroundStyle(.tertiary)
            Text(model.destinationLabel).lineLimit(1)
            Spacer()
            if !model.showsSettings {
                Text("↑↓").font(.system(size: 12, design: .monospaced))
                Text("Select").padding(.trailing, 7)
                Text("↵").font(.system(size: 13))
                Text(model.settings.autoPaste ? "Paste" : "Copy")
            }
        }.font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 18).frame(height: 40)
    }
}
