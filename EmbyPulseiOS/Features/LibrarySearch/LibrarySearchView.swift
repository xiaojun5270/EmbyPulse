import SwiftUI

struct LibrarySearchView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel = LibrarySearchViewModel()

    var body: some View {
        List {
            Section("搜索") {
                HStack(spacing: 10) {
                    TextField("片名 / 关键词", text: $viewModel.query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            Task { await viewModel.search(appState: appState) }
                        }

                    Button("搜索") {
                        Task { await viewModel.search(appState: appState) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }

                HStack {
                    Button("清空") {
                        viewModel.clear()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }

            if let hint = viewModel.actionHint {
                Section {
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("结果") {
                if viewModel.isLoading && viewModel.results.isEmpty {
                    ProgressView("检索中...")
                } else if viewModel.results.isEmpty {
                    Text("暂无结果")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.results) { item in
                        LibrarySearchRow(
                            item: item,
                            baseURL: appState.environment.baseURL,
                            onOpen: {
                                guard let value = item.embyURL, let url = URL(string: value) else { return }
                                openURL(url)
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("媒体库搜索")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.search(appState: appState) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
}

private struct LibrarySearchRow: View {
    let item: LibrarySearchItem
    let baseURL: String
    let onOpen: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: resolveImageURL(path: item.poster, baseURL: baseURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                        Image(systemName: "film")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 56, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer()
                    Text(typeTitle)
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.14))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }

                if !item.year.isEmpty {
                    Text(item.year)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !item.overview.isEmpty {
                    Text(item.overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !item.badges.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.badges.prefix(5)) { badge in
                                Text(badge.text)
                                    .font(.caption2)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("在 Emby 打开") {
                        onOpen()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(item.embyURL == nil || item.embyURL?.isEmpty == true)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var typeTitle: String {
        item.type.lowercased() == "tv" ? "剧集" : "电影"
    }
}

private func resolveImageURL(path: String?, baseURL: String) -> URL? {
    guard let path, !path.isEmpty else { return nil }

    if path.hasPrefix("http://") || path.hasPrefix("https://") {
        return URL(string: path)
    }

    if path.hasPrefix("/") {
        var normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        if !normalized.hasPrefix("http://") && !normalized.hasPrefix("https://") {
            normalized = "http://" + normalized
        }
        return URL(string: normalized + path)
    }

    return nil
}
