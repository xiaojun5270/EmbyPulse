import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroCard

                if let warning = viewModel.warningMessage {
                    warningLabel(warning)
                }
                if let error = viewModel.errorMessage {
                    errorLabel(error)
                }

                sectionCard(
                    title: "媒体库储量",
                    subtitle: "电影、剧集与总收录规模",
                    symbol: "externaldrive.fill.badge.icloud"
                ) {
                    mediaCapacityContent
                }

                sectionCard(
                    title: "核心运营指标",
                    subtitle: "活跃度与播放效率",
                    symbol: "waveform.path.ecg"
                ) {
                    coreMetricsContent
                }

                sectionCard(
                    title: "我的媒体库",
                    subtitle: "库视图与类型分布",
                    symbol: "books.vertical.fill"
                ) {
                    libraryViewsContent
                }

                sectionCard(
                    title: "最近入库",
                    subtitle: "新入库资源流",
                    symbol: "square.stack.3d.down.right.fill"
                ) {
                    latestMediaContent
                }

                sectionCard(
                    title: "最近播放",
                    subtitle: "用户最近观看记录",
                    symbol: "play.rectangle.on.rectangle.fill"
                ) {
                    recentPlaybackContent
                }

                sectionCard(
                    title: "趋势追踪",
                    subtitle: "近期播放时长走势",
                    symbol: "chart.bar.xaxis.ascending"
                ) {
                    trendTrackingContent
                }

                sectionCard(
                    title: "白金观影榜",
                    subtitle: "高活跃用户排行",
                    symbol: "trophy.fill"
                ) {
                    platinumRankingContent
                }

                sectionCard(
                    title: "实时播放",
                    subtitle: "当前在线会话",
                    symbol: "dot.radiowaves.left.and.right"
                ) {
                    realtimeContent
                }
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("仪表盘")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.refresh(appState: appState)
        }
        .refreshable {
            await viewModel.refresh(appState: appState)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emby Pulse 控制台")
                        .font(ConsoleDesign.heroTitleFont)
                        .foregroundStyle(isDark ? .white : .primary)
                    Text("媒体运营态势总览")
                        .font(.footnote)
                        .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))
                }

                Spacer()

                Button {
                    Task { await viewModel.refresh(appState: appState) }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(isDark ? .white : .indigo)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ConsoleDesign.heroBadgeForeground(isDark: isDark))
                        }
                    }
                    .frame(width: 34, height: 34)
                    .background(ConsoleDesign.heroBadgeBackground(isDark: isDark))
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                heroMetric(title: "总播放", value: "\(viewModel.dashboard?.totalPlays ?? 0)")
                heroMetric(title: "活跃用户", value: "\(viewModel.dashboard?.activeUsers ?? 0)")
                heroMetric(title: "实时会话", value: "\(viewModel.liveSessions.count)")
            }

            Text("更新时间：\(lastUpdatedText)")
                .font(.caption)
                .foregroundStyle(isDark ? Color.white.opacity(0.76) : .secondary)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.20, green: 0.28, blue: 0.42), Color(red: 0.15, green: 0.22, blue: 0.33)]
                    : [Color(red: 0.67, green: 0.83, blue: 1.0), Color(red: 0.78, green: 0.94, blue: 0.98)],
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

    private func heroMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(ConsoleDesign.heroPillTitleColor(isDark: isDark))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ConsoleDesign.heroPillValueColor(isDark: isDark))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(ConsoleDesign.heroPillBackground(isDark: isDark))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var mediaCapacityContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            dashboardPill(title: "总收录", value: "\(totalLibraryItems)", tint: .indigo)
            dashboardPill(title: "电影", value: "\(viewModel.dashboard?.library.movie ?? 0)", tint: .blue)
            dashboardPill(title: "剧集", value: "\(viewModel.dashboard?.library.series ?? 0)", tint: .mint)
            dashboardPill(title: "剧集单元", value: "\(viewModel.dashboard?.library.episode ?? 0)", tint: .orange)
        }
    }

    private var coreMetricsContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            dashboardMetricCard("总播放", "\(viewModel.dashboard?.totalPlays ?? 0)", "play.circle.fill", .indigo)
            dashboardMetricCard("活跃用户", "\(viewModel.dashboard?.activeUsers ?? 0)", "person.2.fill", .blue)
            dashboardMetricCard("总时长", formattedHours(from: viewModel.dashboard?.totalDuration ?? 0), "clock.fill", .mint)
            dashboardMetricCard("实时会话", "\(viewModel.liveSessions.count)", "dot.radiowaves.left.and.right", .orange)
        }
    }

    @ViewBuilder
    private var libraryViewsContent: some View {
        if viewModel.libraries.isEmpty {
            emptyCard("暂无媒体库视图")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.libraries) { library in
                        HStack(spacing: 10) {
                            AsyncImage(url: posterURL(itemID: library.id)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    placeholderPoster
                                }
                            }
                            .frame(width: 48, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(library.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text(collectionTypeTitle(library.collectionType))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(width: 220)
                        .padding(12)
                        .background(rowCardBackground)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var latestMediaContent: some View {
        if viewModel.latestMedia.isEmpty {
            emptyCard("暂无最近入库")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.latestMedia.prefix(12)) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            AsyncImage(url: posterURL(itemID: item.id)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    placeholderPoster
                                }
                            }
                            .frame(width: 126, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Text(item.name)
                                .font(.caption.weight(.semibold))
                                .lineLimit(2)
                                .frame(width: 126, alignment: .leading)
                        }
                        .padding(10)
                        .background(rowCardBackground)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentPlaybackContent: some View {
        if viewModel.recentActivities.isEmpty {
            emptyCard("暂无最近播放记录")
        } else {
            VStack(spacing: 8) {
                ForEach(viewModel.recentActivities.prefix(6)) { item in
                    HStack(spacing: 10) {
                        AsyncImage(url: posterURL(itemID: item.itemID)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                placeholderPoster
                            }
                        }
                        .frame(width: 40, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.displayName)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(2)
                            Text("\(item.userName) · \(itemType(item.itemType))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 8)

                        Text(compactDate(item.dateCreated))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(isDark ? 0.2 : 0.12))
                            .clipShape(Capsule())
                    }
                    .padding(12)
                    .background(rowCardBackground)
                }
            }
        }
    }

    @ViewBuilder
    private var trendTrackingContent: some View {
        if viewModel.trendPoints.isEmpty {
            emptyCard("暂无趋势数据")
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Chart(viewModel.trendPoints) { point in
                    BarMark(
                        x: .value("日期", point.label),
                        y: .value("小时", point.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6))
                }

                HStack(spacing: 8) {
                    dashboardPill(title: "累计时长", value: String(format: "%.1f 小时", totalTrendHours), tint: .cyan)
                    dashboardPill(title: "数据点", value: "\(viewModel.trendPoints.count)", tint: .indigo)
                }
            }
            .padding(12)
            .background(rowCardBackground)
        }
    }

    @ViewBuilder
    private var platinumRankingContent: some View {
        HStack(spacing: 8) {
            periodChip(title: "今日", period: .day)
            periodChip(title: "本周", period: .week)
            periodChip(title: "本月", period: .month)
            periodChip(title: "总榜", period: .all)
        }

        if viewModel.platinumUsers.isEmpty {
            emptyCard("暂无榜单数据")
        } else {
            VStack(spacing: 8) {
                ForEach(Array(viewModel.platinumUsers.prefix(5).enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.caption.bold())
                            .frame(width: 36, height: 24)
                            .background(index == 0 ? Color.orange.opacity(0.28) : Color.yellow.opacity(0.18))
                            .clipShape(Capsule())

                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.indigo)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.userName)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text("播放 \(item.plays) 次 · \(String(format: "%.1f", item.totalHours)) 小时")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(rowCardBackground)
                }
            }
        }
    }

    @ViewBuilder
    private var realtimeContent: some View {
        if viewModel.liveSessions.isEmpty {
            emptyCard("当前没有正在播放的会话")
        } else {
            VStack(spacing: 8) {
                ForEach(viewModel.liveSessions.prefix(6)) { session in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.mint)
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.nowPlayingItem?.name ?? "未知内容")
                                .font(.subheadline.weight(.semibold))
                            Text("\(session.userName ?? "未知用户") · \(session.client ?? "未知客户端") · \(session.deviceName ?? "未知设备")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(rowCardBackground)
                }
            }
        }
    }

    private var totalLibraryItems: Int {
        let library = viewModel.dashboard?.library
        return (library?.movie ?? 0) + (library?.series ?? 0) + (library?.episode ?? 0)
    }

    private var totalTrendHours: Double {
        viewModel.trendPoints.reduce(0.0) { $0 + $1.hours }
    }

    private var lastUpdatedText: String {
        guard let date = viewModel.lastUpdatedAt else { return "尚未刷新" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
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
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.indigo)
                    .frame(width: 32, height: 32)
                    .background(Color.indigo.opacity(isDark ? 0.26 : 0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            content()
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.06), radius: 10, x: 0, y: 6)
    }

    private var rowCardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isDark ? Color(red: 0.18, green: 0.20, blue: 0.24).opacity(0.96) : Color.white.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.indigo.opacity(0.08), lineWidth: 1)
            )
    }

    private var cardSurface: Color {
        isDark ? Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.95) : Color.white.opacity(0.88)
    }

    private var placeholderPoster: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDark ? Color(red: 0.18, green: 0.20, blue: 0.24) : Color.white.opacity(0.8))
            Image(systemName: "film.stack")
                .foregroundStyle(.secondary)
        }
    }

    private func dashboardMetricCard(
        _ title: String,
        _ value: String,
        _ symbol: String,
        _ tint: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.weight(.bold))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(rowCardBackground)
    }

    private func dashboardPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(isDark ? 0.24 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(rowCardBackground)
    }

    private func warningLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.orange)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func errorLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formattedHours(from seconds: Int) -> String {
        let hours = Double(seconds) / 3600.0
        return String(format: "%.1f h", hours)
    }

    private func collectionTypeTitle(_ raw: String) -> String {
        switch raw.lowercased() {
        case "movies", "movie":
            return "电影库"
        case "tvshows", "tvshow", "series":
            return "剧集库"
        case "music":
            return "音乐库"
        default:
            return raw.isEmpty ? "未知类型" : raw
        }
    }

    private func itemType(_ raw: String) -> String {
        switch raw.lowercased() {
        case "movie":
            return "电影"
        case "episode":
            return "剧集"
        default:
            return raw
        }
    }

    private func compactDate(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: "Z", with: "")
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) ?? iso.date(from: cleaned) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: date)
        }
        return value.replacingOccurrences(of: "T", with: " ").prefix(16).description
    }

    private func posterURL(itemID: String) -> URL? {
        guard !itemID.isEmpty else { return nil }
        var base = appState.environment.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.hasPrefix("http://") && !base.hasPrefix("https://") {
            base = "http://" + base
        }
        if base.hasSuffix("/") {
            base.removeLast()
        }
        return URL(string: "\(base)/api/proxy/smart_image?item_id=\(itemID)&type=Primary")
    }

    private func periodChip(title: String, period: TopUsersPeriod) -> some View {
        let selected = viewModel.platinumPeriod == period
        return Button {
            guard viewModel.platinumPeriod != period else { return }
            viewModel.platinumPeriod = period
            Task { await viewModel.refreshPlatinumRanking(appState: appState) }
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(
                    selected
                        ? Color.indigo
                        : (isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.78))
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
}
