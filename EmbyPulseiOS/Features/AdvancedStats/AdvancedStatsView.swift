import Charts
import SwiftUI

struct AdvancedStatsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AdvancedStatsViewModel()
    @State private var showAllTopMovies = false
    @State private var showAllRecent = false
    @State private var showAllLatest = false
    @State private var showAllLogs = false
    @State private var filterRefreshTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroPanel

                    sectionHeader(
                        title: "筛选与快照",
                        subtitle: "按用户、类型、排序和周期切换看板",
                        symbol: "slider.horizontal.3"
                    )
                    dashboardGrid(columns: gridColumns(for: proxy.size.width)) {
                        filtersPanel
                        snapshotPanel
                    }

                    if let warning = viewModel.warningMessage {
                        statusBanner(warning, tint: .orange)
                    }
                    if let error = viewModel.errorMessage {
                        statusBanner(error, tint: .red)
                    }

                    sectionHeader(
                        title: "核心运营概览",
                        subtitle: "总览、勋章、设备与偏好分布",
                        symbol: "rectangle.3.group.bubble"
                    )
                    dashboardGrid(columns: gridColumns(for: proxy.size.width)) {
                        overviewSection
                        badgesSection
                        devicesAndClientsSection
                    }

                    sectionHeader(
                        title: "趋势追踪",
                        subtitle: "月度时长和 24 小时活跃度曲线",
                        symbol: "chart.xyaxis.line"
                    )
                    dashboardGrid(columns: gridColumns(for: proxy.size.width)) {
                        monthlyTrendSection
                        hourlySection
                    }

                    sectionHeader(
                        title: "排行与画像",
                        subtitle: "热门内容、活跃用户和观看日志",
                        symbol: "chart.bar.doc.horizontal"
                    )
                    dashboardGrid(columns: gridColumns(for: proxy.size.width)) {
                        topUsersSection
                        topMoviesSection
                        userLogsSection
                    }

                    sectionHeader(
                        title: "内容动态",
                        subtitle: "最近动态、最新入库、媒体库结构",
                        symbol: "clock.arrow.circlepath"
                    )
                    dashboardGrid(columns: gridColumns(for: proxy.size.width)) {
                        recentSection
                        latestSection
                        librarySection
                    }
                }
                .padding(16)
            }
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("数据洞察")
        .overlay {
            if viewModel.isRefreshingAll && viewModel.topMovies.isEmpty && viewModel.topUsers.isEmpty {
                ProgressView("加载中...")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refreshAll(appState: appState) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isRefreshingAll)
            }
        }
        .task {
            await viewModel.loadInitial(appState: appState)
        }
        .refreshable {
            await viewModel.refreshAll(appState: appState)
        }
        .onChange(of: viewModel.selectedUserID) { _ in
            showAllTopMovies = false
            showAllRecent = false
            showAllLogs = false
            viewModel.invalidateForUserChange()
            scheduleRefreshForFilterChange(groups: [.overviewBundle, .topMovies, .recent])
        }
        .onChange(of: viewModel.topMoviesCategory) { _ in
            showAllTopMovies = false
            viewModel.invalidateForTopMoviesFilterChange()
            scheduleRefreshForFilterChange(groups: [.topMovies])
        }
        .onChange(of: viewModel.topMoviesSort) { _ in
            viewModel.invalidateForTopMoviesFilterChange()
            scheduleRefreshForFilterChange(groups: [.topMovies])
        }
        .onChange(of: viewModel.topUsersPeriod) { _ in
            viewModel.invalidateForTopUsersPeriodChange()
            scheduleRefreshForFilterChange(groups: [.topUsers])
        }
        .onDisappear {
            filterRefreshTask?.cancel()
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("数据洞察仪表板")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(isDark ? .white : .primary)

            Text("用户画像、观影趋势、活跃排行、媒体库结构一屏联动")
                .font(.footnote)
                .foregroundStyle(isDark ? Color.white.opacity(0.82) : .secondary)

            HStack(spacing: 8) {
                Text("当前用户：\(selectedUserTitle)")
                    .font(.caption.weight(.semibold))
                if let hour = viewModel.dominantActiveHour, hour.plays > 0 {
                    Text("高峰：\(hour.hour):00")
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(isDark ? 0.14 : 0.7))
            .clipShape(Capsule())

            HStack(spacing: 8) {
                heroPill(title: "模块", value: "\(viewModel.loadedGroups.count)/\(AdvancedStatsLoadGroup.allCases.count)")
                heroPill(title: "更新", value: viewModel.isRefreshingAll || viewModel.isLoading ? "同步中" : "已完成")
                heroPill(title: "用户", value: selectedUserTitle)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.20, green: 0.28, blue: 0.42), Color(red: 0.16, green: 0.22, blue: 0.34)]
                    : [Color(red: 0.79, green: 0.89, blue: 1.0), Color(red: 0.86, green: 0.98, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(isDark ? 0.16 : 0.5), lineWidth: 1)
        )
    }

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(isDark ? Color.white.opacity(0.72) : .secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(isDark ? 0.10 : 0.68))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var filtersPanel: some View {
        statsPanel(title: "筛选") {
            Picker("用户", selection: $viewModel.selectedUserID) {
                Text("全部用户").tag("all")
                ForEach(viewModel.users) { user in
                    Text(user.userName).tag(user.userID)
                }
            }
            .pickerStyle(.menu)

            Picker("内容类型", selection: $viewModel.topMoviesCategory) {
                ForEach(TopMoviesCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.segmented)

            Picker("排序", selection: $viewModel.topMoviesSort) {
                ForEach(TopMoviesSort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .pickerStyle(.segmented)

            Picker("活跃周期", selection: $viewModel.topUsersPeriod) {
                ForEach(TopUsersPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var snapshotPanel: some View {
        statsPanel(title: "快照") {
            HStack {
                Text("当前用户")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(selectedUserTitle)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("最后刷新")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(lastUpdatedText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let hour = viewModel.dominantActiveHour, hour.plays > 0 {
                HStack {
                    Text("高峰时段")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(hour.hour):00 · \(hour.plays) 次")
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private var overviewSection: some View {
        statsPanel(title: "总览") {
            if viewModel.isLoading(.overviewBundle) && viewModel.userDetails == nil {
                ProgressView("加载总览中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let details = viewModel.userDetails {
                let overview = details.overview
                let monthlyHours = viewModel.monthlyPoints.reduce(0.0) { $0 + $1.hours }
                let completionRate = completionRateText(plays: overview.totalPlays, accountAgeDays: overview.accountAgeDays)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    StatCard(title: "播放次数", value: "\(overview.totalPlays)", systemImage: "play.circle")
                    StatCard(title: "总时长", value: hoursText(overview.totalDuration), systemImage: "clock")
                    StatCard(title: "平均时长", value: hoursText(overview.avgDuration), systemImage: "timer")
                    StatCard(title: "活跃天数", value: "\(overview.accountAgeDays) 天", systemImage: "calendar")
                    StatCard(title: "近12月总时长", value: String(format: "%.1f 小时", monthlyHours), systemImage: "chart.line.uptrend.xyaxis")
                    StatCard(title: "活跃密度", value: completionRate, systemImage: "gauge.with.dots.needle.67percent")
                }

                if let topFavorite = details.topFavorite, !topFavorite.itemName.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("偏爱内容")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(topFavorite.itemName)
                            .font(.headline)
                            .lineLimit(2)
                        Text("播放 \(topFavorite.playCount) 次 · \(hoursText(topFavorite.totalDuration))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text(viewModel.isLoading ? "加载中..." : "暂无总览数据")
                    .foregroundStyle(.secondary)
            }

            if let error = viewModel.error(for: .overviewBundle) {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var monthlyTrendSection: some View {
        statsPanel(title: "月度时长趋势") {
            if viewModel.isLoading(.overviewBundle) && viewModel.monthlyPoints.isEmpty {
                ProgressView("加载趋势中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.monthlyPoints.isEmpty {
                Text("暂无月度趋势数据")
                    .foregroundStyle(.secondary)
            } else {
                Chart(viewModel.monthlyPoints) { point in
                    AreaMark(
                        x: .value("月份", point.month),
                        y: .value("小时", point.hours)
                    )
                    .foregroundStyle(.mint.opacity(0.15))

                    LineMark(
                        x: .value("月份", point.month),
                        y: .value("小时", point.hours)
                    )
                    .foregroundStyle(.mint)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("月份", point.month),
                        y: .value("小时", point.hours)
                    )
                    .foregroundStyle(.mint)
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private var hourlySection: some View {
        statsPanel(title: "24小时活跃分布") {
            if viewModel.isLoading(.overviewBundle) && viewModel.userDetails == nil {
                ProgressView("加载活跃分布中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.hourlyPoints.allSatisfy({ $0.plays == 0 }) {
                Text("暂无活跃时段数据")
                    .foregroundStyle(.secondary)
            } else {
                Chart(viewModel.hourlyPoints) { point in
                    BarMark(
                        x: .value("小时", point.hour),
                        y: .value("播放次数", point.plays)
                    )
                    .foregroundStyle(.indigo.opacity(0.7))
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 4))
                }
            }
        }
    }

    @ViewBuilder
    private var topMoviesSection: some View {
        statsPanel(title: "热门内容 TOP 10") {
            if viewModel.isLoading(.topMovies) && viewModel.topMovies.isEmpty {
                ProgressView("加载热门内容中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.topMovies.isEmpty {
                Text("暂无热门内容数据")
                    .foregroundStyle(.secondary)
            } else {
                let limit = showAllTopMovies ? min(viewModel.topMovies.count, 50) : min(viewModel.topMovies.count, 10)
                let maxScore = Double(movieScore(viewModel.topMovies.first))

                ForEach(Array(viewModel.topMovies.prefix(limit).enumerated()), id: \.element.id) { index, item in
                    TopMovieRow(
                        rank: index + 1,
                        item: item,
                        baseURL: appState.environment.baseURL,
                        scoreValue: Double(movieScore(item)),
                        maxScore: maxScore,
                        sort: viewModel.topMoviesSort
                    )
                }

                if viewModel.topMovies.count > 10 {
                    Button(showAllTopMovies ? "收起" : "查看更多") {
                        showAllTopMovies.toggle()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            if let error = viewModel.error(for: .topMovies) {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var topUsersSection: some View {
        statsPanel(title: "活跃用户排行") {
            if viewModel.isLoading(.topUsers) && viewModel.topUsers.isEmpty {
                ProgressView("加载活跃用户中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.topUsers.isEmpty {
                Text("暂无用户排行数据")
                    .foregroundStyle(.secondary)
            } else {
                let maxTime = Double(viewModel.topUsers.map(\.totalTime).max() ?? 1)
                ForEach(Array(viewModel.topUsers.enumerated()), id: \.element.id) { index, item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .frame(width: 20, height: 20)
                                .background(Color.blue.opacity(0.14))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.userName)
                                    .font(.body)
                                Text("播放 \(item.plays) 次 · \(hoursText(item.totalTime))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(progressText(value: Double(item.totalTime), max: maxTime))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: Double(item.totalTime), total: maxTime)
                            .tint(.blue)
                    }
                    .padding(.vertical, 2)
                }
            }

            if let error = viewModel.error(for: .topUsers) {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var badgesSection: some View {
        statsPanel(title: "观影勋章") {
            if viewModel.badges.isEmpty {
                Text("暂无勋章")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.badges) { badge in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: badgeSymbol(from: badge.icon))
                            .font(.body)
                            .foregroundStyle(badgeTintColor(from: badge))
                            .frame(width: 28, height: 28)
                            .background(badgeTintColor(from: badge).opacity(0.16))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(badge.name)
                                .font(.headline)
                            if !badge.description.isEmpty {
                                Text(badge.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var devicesAndClientsSection: some View {
        statsPanel(title: "设备与偏好") {
            if let details = viewModel.userDetails {
                let total = max(1, details.preference.moviePlays + details.preference.episodePlays)
                let movieRate = Double(details.preference.moviePlays) / Double(total)
                let episodeRate = Double(details.preference.episodePlays) / Double(total)

                VStack(alignment: .leading, spacing: 6) {
                    Text("内容偏好")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("电影 \(Int(movieRate * 100))% · 剧集 \(Int(episodeRate * 100))%")
                        .font(.headline)
                }
                .padding(.vertical, 2)

                if details.devices.isEmpty {
                    Text("暂无设备分布")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("常用设备")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(details.devices.prefix(5)) { item in
                        HStack {
                            Text(item.label)
                            Spacer()
                            Text("\(item.plays)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                    }
                }

                if details.clients.isEmpty {
                    Text("暂无客户端分布")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("常用客户端")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(details.clients.prefix(5)) { item in
                        HStack {
                            Text(item.label)
                            Spacer()
                            Text("\(item.plays)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                    }
                }
            } else {
                Text("暂无偏好数据")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var userLogsSection: some View {
        statsPanel(title: "观看日志（画像）") {
            let logs = viewModel.userDetails?.logs ?? []
            if logs.isEmpty {
                Text("暂无观看日志")
                    .foregroundStyle(.secondary)
            } else {
                let limit = showAllLogs ? min(logs.count, 40) : min(logs.count, 10)
                ForEach(Array(logs.prefix(limit))) { log in
                    UserPlaybackLogRow(
                        log: log,
                        baseURL: appState.environment.baseURL
                    )
                }

                if logs.count > 10 {
                    Button(showAllLogs ? "收起" : "查看更多") {
                        showAllLogs.toggle()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        statsPanel(title: "最近动态") {
            if viewModel.isLoading(.recent) && viewModel.recentActivities.isEmpty {
                ProgressView("加载动态中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.recentActivities.isEmpty {
                Text("暂无动态")
                    .foregroundStyle(.secondary)
            } else {
                let limit = showAllRecent ? min(viewModel.recentActivities.count, 50) : min(viewModel.recentActivities.count, 15)
                ForEach(viewModel.recentActivities.prefix(limit)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayName)
                            .font(.headline)
                            .lineLimit(2)
                        Text("\(item.userName) · \(itemTypeTitle(item.itemType))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(dateLine(item.dateCreated))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                if viewModel.recentActivities.count > 15 {
                    Button(showAllRecent ? "收起" : "查看更多") {
                        showAllRecent.toggle()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            if let error = viewModel.error(for: .recent) {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var latestSection: some View {
        statsPanel(title: "最新入库") {
            if viewModel.isLoading(.latest) && viewModel.latestMedia.isEmpty {
                ProgressView("加载最新入库中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.latestMedia.isEmpty {
                Text("暂无入库数据")
                    .foregroundStyle(.secondary)
            } else {
                let limit = showAllLatest ? min(viewModel.latestMedia.count, 40) : min(viewModel.latestMedia.count, 12)
                ForEach(viewModel.latestMedia.prefix(limit)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                            .lineLimit(2)

                        HStack(spacing: 10) {
                            Text(item.type == "Movie" ? "电影" : "剧集")
                            if let year = item.year {
                                Text("\(year)")
                            }
                            if let rating = item.rating {
                                Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if let created = item.dateCreated, !created.isEmpty {
                            Text("入库时间：\(dateLine(created))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }

                if viewModel.latestMedia.count > 12 {
                    Button(showAllLatest ? "收起" : "查看更多") {
                        showAllLatest.toggle()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            if let error = viewModel.error(for: .latest) {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var librarySection: some View {
        statsPanel(title: "媒体库视图") {
            if viewModel.isLoading(.libraries) && viewModel.libraries.isEmpty {
                ProgressView("加载媒体库中...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.libraries.isEmpty {
                Text("暂无媒体库信息")
                    .foregroundStyle(.secondary)
            } else {
                if !viewModel.libraryTypeSummaries.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.libraryTypeSummaries) { summary in
                                Text("\(summary.displayName) \(summary.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.cyan.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                ForEach(viewModel.libraries) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                            Text(collectionTypeTitle(item.collectionType))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(item.type)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            if let error = viewModel.error(for: .libraries) {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(isDark ? 0.22 : 0.14))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dashboardGrid<Content: View>(
        columns: [GridItem],
        @ViewBuilder content: () -> Content
    ) -> some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            content()
        }
    }

    private func gridColumns(for width: CGFloat) -> [GridItem] {
        if width >= 760 {
            return [
                GridItem(.flexible(minimum: 280), spacing: 12, alignment: .top),
                GridItem(.flexible(minimum: 280), spacing: 12, alignment: .top)
            ]
        }
        return [GridItem(.flexible(), spacing: 12, alignment: .top)]
    }

    private func statsPanel<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func statusBanner(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var cardSurface: Color {
        isDark
            ? Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.95)
            : Color.white.opacity(0.9)
    }

    private var borderColor: Color {
        isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.05)
    }

    private var pageGradient: LinearGradient {
        if isDark {
            return LinearGradient(
                colors: [Color(red: 0.06, green: 0.09, blue: 0.14), Color(red: 0.08, green: 0.13, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color(red: 0.96, green: 0.97, blue: 1.0), Color(red: 0.94, green: 0.99, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var isDark: Bool {
        appState.appearanceMode == .dark
    }

    private func hoursText(_ seconds: Int) -> String {
        if seconds < 3600 {
            return "\(max(1, Int(round(Double(seconds) / 60.0)))) 分钟"
        }
        return String(format: "%.1f 小时", Double(seconds) / 3600.0)
    }

    private var selectedUserTitle: String {
        if viewModel.selectedUserID == "all" {
            return "全部用户"
        }
        return viewModel.users.first(where: { $0.userID == viewModel.selectedUserID })?.userName ?? "未知用户"
    }

    private var lastUpdatedText: String {
        guard let date = viewModel.lastUpdatedAt else { return "尚未刷新" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    private func scheduleRefreshForFilterChange(groups: [AdvancedStatsLoadGroup]) {
        filterRefreshTask?.cancel()
        filterRefreshTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.reload(groups: groups, appState: appState, force: true)
        }
    }

    private func movieScore(_ item: TopMovieItem?) -> Int {
        guard let item else { return 0 }
        switch viewModel.topMoviesSort {
        case .count:
            return item.playCount
        case .time:
            return item.totalTime
        }
    }

    private func completionRateText(plays: Int, accountAgeDays: Int) -> String {
        guard accountAgeDays > 0 else { return "--" }
        let value = Double(plays) / Double(accountAgeDays)
        return String(format: "%.1f 次/天", value)
    }

    private func progressText(value: Double, max: Double) -> String {
        guard max > 0 else { return "0%" }
        return "\(Int((value / max) * 100))%"
    }

    private func itemTypeTitle(_ value: String) -> String {
        switch value.lowercased() {
        case "movie":
            return "电影"
        case "episode":
            return "剧集"
        default:
            return value.isEmpty ? "未知" : value
        }
    }

    private func collectionTypeTitle(_ value: String) -> String {
        switch value.lowercased() {
        case "movies", "movie":
            return "电影库"
        case "tvshows", "tvshow", "series":
            return "剧集库"
        case "music":
            return "音乐库"
        case "books":
            return "图书库"
        default:
            return value.isEmpty ? "未知类型" : value
        }
    }

    private func badgeSymbol(from raw: String) -> String {
        let value = raw.lowercased()
        if value.contains("moon") { return "moon.fill" }
        if value.contains("champagne") { return "sparkles" }
        if value.contains("fire") { return "flame.fill" }
        if value.contains("fish") { return "fish.fill" }
        if value.contains("sun") { return "sun.max.fill" }
        if value.contains("gamepad") { return "gamecontroller.fill" }
        if value.contains("repeat") { return "repeat.circle.fill" }
        if value.contains("film") { return "film.fill" }
        if value.contains("tv") { return "tv.fill" }
        return "medal.fill"
    }

    private func badgeTintColor(from badge: StatBadge) -> Color {
        let text = "\(badge.color) \(badge.background)".lowercased()
        if text.contains("red") { return .red }
        if text.contains("pink") { return .pink }
        if text.contains("purple") { return .purple }
        if text.contains("indigo") { return .indigo }
        if text.contains("blue") { return .blue }
        if text.contains("cyan") { return .cyan }
        if text.contains("emerald") || text.contains("green") { return .green }
        if text.contains("amber") || text.contains("yellow") { return .orange }
        return .teal
    }

    private func dateLine(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: "Z", with: "")
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) ?? iso.date(from: cleaned) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: date)
        }
        return value.replacingOccurrences(of: "T", with: " ").prefix(16).description
    }
}

private struct TopMovieRow: View {
    @EnvironmentObject private var appState: AppState
    let rank: Int
    let item: TopMovieItem
    let baseURL: String
    let scoreValue: Double
    let maxScore: Double
    let sort: TopMoviesSort

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("\(rank)")
                    .font(.caption)
                    .frame(width: 22, height: 22)
                    .background(rank <= 3 ? Color.orange.opacity(0.2) : rowSurface)
                    .clipShape(Circle())

                AsyncImage(url: posterURL(path: item.smartPoster)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(rowSurface)
                            Image(systemName: "film")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 34, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.itemName)
                        .font(.body)
                        .lineLimit(2)
                    Text("播放 \(item.playCount) 次 · \(String(format: "%.1f", item.totalHours)) 小时")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(progressText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: scoreValue, total: max(maxScore, 1))
                .tint(sort == .count ? .orange : .mint)
        }
        .padding(.vertical, 2)
    }

    private var progressText: String {
        guard maxScore > 0 else { return "0%" }
        return "\(Int((scoreValue / maxScore) * 100))%"
    }

    private var rowSurface: Color {
        appState.appearanceMode == .dark
            ? Color(red: 0.20, green: 0.22, blue: 0.26)
            : Color.white.opacity(0.82)
    }

    private func posterURL(path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }

        var normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        if !normalized.hasPrefix("http://") && !normalized.hasPrefix("https://") {
            normalized = "http://" + normalized
        }
        return URL(string: normalized + path)
    }
}

private struct UserPlaybackLogRow: View {
    @EnvironmentObject private var appState: AppState
    let log: RecentPlaybackLog
    let baseURL: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: posterURL(path: log.smartPoster)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(rowSurface)
                        Image(systemName: "play.rectangle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 34, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text(log.itemName)
                    .font(.body)
                    .lineLimit(2)
                Text("\(typeTitle(log.itemType)) · \(durationTitle(log.playDuration)) · \(log.device)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dateTitle(log.dateCreated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var rowSurface: Color {
        appState.appearanceMode == .dark
            ? Color(red: 0.20, green: 0.22, blue: 0.26)
            : Color.white.opacity(0.82)
    }

    private func posterURL(path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }

        var normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        if !normalized.hasPrefix("http://") && !normalized.hasPrefix("https://") {
            normalized = "http://" + normalized
        }
        return URL(string: normalized + path)
    }

    private func typeTitle(_ raw: String) -> String {
        switch raw.lowercased() {
        case "movie":
            return "电影"
        case "episode":
            return "剧集"
        default:
            return raw.isEmpty ? "未知" : raw
        }
    }

    private func durationTitle(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)秒"
        }
        if seconds < 3600 {
            return "\(Int(round(Double(seconds) / 60.0)))分钟"
        }
        return String(format: "%.1f小时", Double(seconds) / 3600.0)
    }

    private func dateTitle(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: "Z", with: "")
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) ?? iso.date(from: cleaned) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: date)
        }
        return value.replacingOccurrences(of: "T", with: " ").prefix(16).description
    }
}
