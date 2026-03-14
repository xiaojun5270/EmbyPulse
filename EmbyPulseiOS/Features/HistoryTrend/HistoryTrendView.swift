import SwiftUI

struct HistoryTrendView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HistoryTrendViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroPanel
                filterSection
                podiumSection
                shortlistSection
            }
            .padding(ConsoleDesign.pagePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("内容排行")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refreshRanking(appState: appState) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadInitial(appState: appState)
        }
        .refreshable {
            await viewModel.refreshRanking(appState: appState)
        }
        .onChange(of: viewModel.selectedUserID) { _ in
            Task { await viewModel.refreshRanking(appState: appState) }
        }
        .onChange(of: viewModel.category) { _ in
            Task { await viewModel.refreshRanking(appState: appState) }
        }
        .onChange(of: viewModel.period) { _ in
            Task { await viewModel.refreshRanking(appState: appState) }
        }
        .onChange(of: viewModel.sortBy) { _ in
            Task { await viewModel.refreshRanking(appState: appState) }
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("年度风云榜")
                        .font(ConsoleDesign.heroTitleFont)
                        .foregroundStyle(isDark ? .white : .primary)
                    Text("热度与观影时长双维度排名")
                        .font(.footnote)
                        .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))
                }
                Spacer()
                Image(systemName: "trophy.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConsoleDesign.heroBadgeForeground(isDark: isDark))
                    .padding(8)
                    .background(ConsoleDesign.heroBadgeBackground(isDark: isDark))
                    .clipShape(Circle())
            }

            HStack(spacing: 8) {
                heroPill(title: "榜单", value: viewModel.period.title)
                heroPill(title: "分类", value: viewModel.category.title)
                heroPill(title: "条目", value: "\(viewModel.rankingItems.count)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.24, green: 0.26, blue: 0.40), Color(red: 0.18, green: 0.20, blue: 0.31)]
                    : [Color(red: 0.83, green: 0.87, blue: 1.0), Color(red: 0.88, green: 0.95, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: ConsoleDesign.heroCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ConsoleDesign.heroCornerRadius, style: .continuous)
                .stroke(ConsoleDesign.heroBorderColor(isDark: isDark), lineWidth: 1)
        )
    }

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(ConsoleDesign.heroPillTitleColor(isDark: isDark))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ConsoleDesign.heroPillValueColor(isDark: isDark))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConsoleDesign.heroPillBackground(isDark: isDark))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var filterSection: some View {
        sectionCard(
            title: "榜单参数",
            subtitle: "切换用户、分类、排序和统计时段",
            symbol: "line.3.horizontal.decrease.circle.fill"
        ) {
            Picker("用户", selection: $viewModel.selectedUserID) {
                Text("全服").tag("all")
                ForEach(viewModel.users) { user in
                    Text(user.userName).tag(user.userID)
                }
            }
            .pickerStyle(.menu)

            Picker("分类", selection: $viewModel.category) {
                Text("全局").tag(TopMoviesCategory.all)
                Text("电影").tag(TopMoviesCategory.movie)
                Text("剧集").tag(TopMoviesCategory.episode)
            }
            .pickerStyle(.segmented)

            Picker("排序", selection: $viewModel.sortBy) {
                ForEach(TopMoviesSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .pickerStyle(.segmented)

            Picker("时段", selection: $viewModel.period) {
                ForEach(TopMoviesPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
    }

    private var podiumSection: some View {
        sectionCard(
            title: "荣耀领奖台",
            subtitle: "TOP 3 年度风云内容",
            symbol: "rosette"
        ) {
            if viewModel.isLoading && viewModel.rankingItems.isEmpty {
                ProgressView("正在生成榜单...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 22)
            } else if viewModel.rankingItems.isEmpty {
                emptyState("当前筛选下暂无排行数据")
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    podiumCard(item: rankedItem(at: 1), rank: 2)
                    podiumCard(item: rankedItem(at: 0), rank: 1)
                    podiumCard(item: rankedItem(at: 2), rank: 3)
                }
            }
        }
    }

    private var shortlistSection: some View {
        sectionCard(
            title: "极客入围名单",
            subtitle: "TOP 4 - TOP 50",
            symbol: "list.number"
        ) {
            if viewModel.rankingItems.count <= 3 {
                emptyState("暂无更多入围名单")
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.rankingItems.dropFirst(3).prefix(47).enumerated()), id: \.element.id) { index, item in
                        shortlistRow(item: item, rank: index + 4)
                    }
                }
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ConsoleDesign.sectionTitleFont)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            content()
        }
        .padding(ConsoleDesign.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .fill(cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    private func rankedItem(at index: Int) -> TopMovieItem? {
        guard index < viewModel.rankingItems.count else { return nil }
        return viewModel.rankingItems[index]
    }

    private func podiumCard(item: TopMovieItem?, rank: Int) -> some View {
        let posterWidth: CGFloat = rank == 1 ? 108 : 86
        let posterHeight: CGFloat = rank == 1 ? 156 : 124

        return VStack(spacing: 8) {
            if let item {
                AsyncImage(url: posterURL(for: item)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        posterPlaceholder
                    }
                }
                .frame(width: posterWidth, height: posterHeight)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(item.itemName)
                    .font(.caption.weight(.bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: posterWidth)

                Text("播放 \(item.playCount) 次")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(placeholderSurface)
                    .frame(width: posterWidth, height: posterHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(rowSurface)
        )
        .overlay(alignment: .topLeading) {
            Text("#\(rank)")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(rank == 1 ? Color.yellow.opacity(0.28) : Color.gray.opacity(0.2))
                .clipShape(Capsule())
                .padding(10)
        }
    }

    private func shortlistRow(item: TopMovieItem, rank: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 30)

            AsyncImage(url: posterURL(for: item)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    posterPlaceholder
                }
            }
            .frame(width: 40, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.itemName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("播放 \(item.playCount) 次 · \(String(format: "%.1f", item.totalHours)) 小时")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(rowSurface)
        )
    }

    private var posterPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(placeholderSurface)
            Image(systemName: "film.stack")
                .foregroundStyle(.secondary)
        }
    }

    private var cardSurface: Color {
        isDark ? Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.95) : Color.white.opacity(0.88)
    }

    private var rowSurface: Color {
        isDark ? Color(red: 0.19, green: 0.21, blue: 0.25).opacity(0.95) : Color.white.opacity(0.78)
    }

    private var borderColor: Color {
        isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.05)
    }

    private var placeholderSurface: Color {
        isDark ? Color(red: 0.18, green: 0.20, blue: 0.24) : Color.white.opacity(0.8)
    }

    private var pageGradient: LinearGradient {
        if isDark {
            return LinearGradient(
                colors: [Color(red: 0.07, green: 0.10, blue: 0.16), Color(red: 0.08, green: 0.14, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color(red: 0.96, green: 0.97, blue: 1.0), Color(red: 0.95, green: 0.99, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var isDark: Bool {
        appState.appearanceMode == .dark
    }

    private func posterURL(for item: TopMovieItem) -> URL? {
        if let smartPoster = item.smartPoster, !smartPoster.isEmpty {
            if smartPoster.hasPrefix("http://") || smartPoster.hasPrefix("https://") {
                return URL(string: smartPoster)
            }
            var base = appState.environment.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !base.hasPrefix("http://") && !base.hasPrefix("https://") {
                base = "http://" + base
            }
            if base.hasSuffix("/") {
                base.removeLast()
            }
            return URL(string: base + smartPoster)
        }

        guard !item.itemID.isEmpty else { return nil }
        var base = appState.environment.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.hasPrefix("http://") && !base.hasPrefix("https://") {
            base = "http://" + base
        }
        if base.hasSuffix("/") {
            base.removeLast()
        }
        return URL(string: "\(base)/api/proxy/smart_image?item_id=\(item.itemID)&type=Primary")
    }
}
