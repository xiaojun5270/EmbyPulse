import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    @State private var heroOffset: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroCard
                momentumStrip

                if let warning = viewModel.warningMessage {
                    warningLabel(warning)
                }

                if let error = viewModel.errorMessage {
                    errorLabel(error)
                }

                overviewStage

                sectionCard(
                    title: "媒体库存量",
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

                activityShowcase

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
            .padding(.bottom, 28)
        }
        .coordinateSpace(name: "dashboard-scroll")
        .background(pageGradient.ignoresSafeArea())
        .overlay(alignment: .top) {
            if shouldShowCompactHeader {
                compactHeader
                    .padding(.horizontal, ConsoleDesign.pagePadding)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("仪表盘")
        .navigationBarTitleDisplayMode(.large)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: shouldShowCompactHeader)
        .onPreferenceChange(DashboardHeroOffsetPreferenceKey.self) { value in
            heroOffset = value
        }
        .task {
            await viewModel.refresh(appState: appState)
        }
        .refreshable {
            await viewModel.refresh(appState: appState)
        }
    }

    private var heroCard: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("dashboard-scroll")).minY
            let stretch = max(0, minY)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Emby Pulse 控制台")
                            .font(ConsoleDesign.heroTitleFont)
                            .foregroundStyle(.white)

                        Text("媒体运营态势总览")
                            .font(.footnote)
                            .foregroundStyle(Color.white.opacity(0.78))

                        HStack(spacing: 8) {
                            heroTag("iOS 原生")
                            heroTag("实时总览")
                            heroTag(viewModel.isLoading ? "刷新中" : "顺滑滚动")
                        }
                    }

                    Spacer(minLength: 12)

                    Button {
                        Task { await viewModel.refresh(appState: appState) }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    heroMetric(title: "总播放", value: "\(viewModel.dashboard?.totalPlays ?? 0)")
                    heroMetric(title: "活跃用户", value: "\(viewModel.dashboard?.activeUsers ?? 0)")
                    heroMetric(title: "实时会话", value: "\(viewModel.liveSessions.count)")
                }

                HStack(spacing: 10) {
                    Label("更新于 \(lastUpdatedText)", systemImage: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.78))

                    Spacer(minLength: 0)

                    Text(viewModel.liveSessions.isEmpty ? "当前平台空闲" : "当前 \(viewModel.liveSessions.count) 个在线会话")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .background(heroBackground)
            .clipShape(RoundedRectangle(cornerRadius: ConsoleDesign.heroCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ConsoleDesign.heroCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.24 : 0.12), radius: 16, x: 0, y: 12)
            .offset(y: minY < 0 ? minY * 0.14 : 0)
            .scaleEffect(stretch > 0 ? 1 + stretch / 900 : 1, anchor: .top)
            .preference(key: DashboardHeroOffsetPreferenceKey.self, value: minY)
            .preference(key: DashboardChromeProgressPreferenceKey.self, value: collapseProgress(for: minY))
        }
        .frame(height: 212)
    }

    private var shouldShowCompactHeader: Bool {
        heroOffset < -110
    }

    private var compactHeader: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pulse 总览")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(compactHeaderStatus)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            compactBadge(title: "播放", value: "\(viewModel.dashboard?.totalPlays ?? 0)", tint: .indigo)
            compactBadge(title: "用户", value: "\(viewModel.dashboard?.activeUsers ?? 0)", tint: .blue)
            compactBadge(title: "会话", value: "\(viewModel.liveSessions.count)", tint: .mint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    LinearGradient(
                        colors: [Color.white.opacity(isDark ? 0.10 : 0.28), Color.white.opacity(0.01)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .shadow(color: Color.black.opacity(isDark ? 0.22 : 0.08), radius: 12, x: 0, y: 6)
        )
    }

    private var compactHeaderStatus: String {
        if viewModel.isLoading {
            return "数据刷新中"
        }
        if !viewModel.liveSessions.isEmpty {
            return "当前有 \(viewModel.liveSessions.count) 个在线会话"
        }
        return "当前平台运行平稳"
    }

    private func compactBadge(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(tint.opacity(isDark ? 0.22 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func collapseProgress(for offset: CGFloat) -> CGFloat {
        min(max((-offset - 8) / 140, 0), 1)
    }

    private var heroBackground: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.16, green: 0.25, blue: 0.42), Color(red: 0.11, green: 0.17, blue: 0.30)]
                    : [Color(red: 0.17, green: 0.43, blue: 0.87), Color(red: 0.11, green: 0.68, blue: 0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 160, height: 160)
                .blur(radius: 18)
                .offset(x: 28, y: -36)

            Circle()
                .fill(Color.cyan.opacity(0.22))
                .frame(width: 120, height: 120)
                .blur(radius: 10)
                .offset(x: -120, y: 92)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 136, height: 136)
                .rotationEffect(.degrees(14))
                .offset(x: 38, y: 68)
        }
    }

    private func heroTag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.14))
            .clipShape(Capsule())
    }

    private func heroMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.72))

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var momentumStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                snapshotPill(
                    title: "媒体总量",
                    value: "\(totalLibraryItems)",
                    subtitle: "库存总览",
                    tint: .indigo
                )

                snapshotPill(
                    title: "趋势时长",
                    value: String(format: "%.1f h", totalTrendHours),
                    subtitle: "近期播放",
                    tint: .cyan
                )

                snapshotPill(
                    title: "最新入库",
                    value: "\(viewModel.latestMedia.count)",
                    subtitle: "内容更新",
                    tint: .mint
                )

                snapshotPill(
                    title: "在线会话",
                    value: "\(viewModel.liveSessions.count)",
                    subtitle: "当前活跃",
                    tint: .orange
                )
            }
            .padding(.horizontal, 1)
        }
    }

    private var overviewStage: some View {
        sectionCard(
            title: "运营总览",
            subtitle: "把库存、热度和活跃状态折叠进一屏",
            symbol: "square.grid.3x3.square"
        ) {
            VStack(spacing: 12) {
                overviewLeadPanel

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    overviewMiniMetric(
                        title: "媒体库存",
                        value: "\(totalLibraryItems)",
                        note: "电影 \(viewModel.dashboard?.library.movie ?? 0) · 剧集 \(viewModel.dashboard?.library.series ?? 0)",
                        tint: .indigo,
                        symbol: "shippingbox.fill"
                    )
                    overviewMiniMetric(
                        title: "总播放",
                        value: "\(viewModel.dashboard?.totalPlays ?? 0)",
                        note: "近期趋势 \(String(format: "%.1f", totalTrendHours))h",
                        tint: .blue,
                        symbol: "play.circle.fill"
                    )
                    overviewMiniMetric(
                        title: "活跃用户",
                        value: "\(viewModel.dashboard?.activeUsers ?? 0)",
                        note: "榜单人数 \(viewModel.platinumUsers.count)",
                        tint: .mint,
                        symbol: "person.2.fill"
                    )
                    overviewMiniMetric(
                        title: "实时会话",
                        value: "\(viewModel.liveSessions.count)",
                        note: viewModel.liveSessions.isEmpty ? "当前没有播放" : "平台正在活跃中",
                        tint: .orange,
                        symbol: "dot.radiowaves.left.and.right"
                    )
                }
            }
        }
    }

    private var overviewLeadPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.liveSessions.isEmpty ? "平台节奏平稳" : "当前播放热度正在上升")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)

                    Text("用一张卡片先看库存、在线会话和近几天播放强度。")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.76))
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(lastUpdatedText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("最近同步")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.72))
                }
            }

            HStack(spacing: 10) {
                leadPanelMetric(title: "库存", value: "\(totalLibraryItems)")
                leadPanelMetric(title: "播放", value: "\(viewModel.dashboard?.totalPlays ?? 0)")
                leadPanelMetric(title: "在线", value: "\(viewModel.liveSessions.count)")
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.20, green: 0.28, blue: 0.46), Color(red: 0.10, green: 0.18, blue: 0.32)]
                    : [Color(red: 0.20, green: 0.47, blue: 0.90), Color(red: 0.07, green: 0.66, blue: 0.74)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private func leadPanelMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.74))

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func overviewMiniMetric(
        title: String,
        value: String,
        note: String,
        tint: Color,
        symbol: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .lineLimit(1)

            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .padding(14)
        .background(rowCardBackground)
    }

    private var activityShowcase: some View {
        sectionCard(
            title: "动态现场",
            subtitle: "把新入库、当前会话和最近播放放到同一块舞台里",
            symbol: "sparkles.tv"
        ) {
            VStack(spacing: 12) {
                activityHeadline

                if let featured = viewModel.latestMedia.first {
                    featuredLatestCard(featured)
                } else {
                    emptyCard("暂无可展示的新入库内容")
                }

                HStack(spacing: 10) {
                    spotlightCountCard(
                        title: "新入库",
                        value: "\(viewModel.latestMedia.count)",
                        subtitle: "最近同步到媒体库",
                        tint: .mint
                    )
                    spotlightCountCard(
                        title: "最近播放",
                        value: "\(min(viewModel.recentActivities.count, 6))",
                        subtitle: "本页展示条目",
                        tint: .blue
                    )
                }

                liveSessionSpotlight
            }
        }
    }

    private var activityHeadline: some View {
        HStack {
            Text(viewModel.liveSessions.isEmpty ? "当前更适合浏览新入库内容" : "当前有设备在线，适合关注会话状态")
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 0)

            Text(viewModel.liveSessions.isEmpty ? "静态时段" : "活跃时段")
                .font(.caption.weight(.semibold))
                .foregroundStyle(viewModel.liveSessions.isEmpty ? Color.secondary : Color.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((viewModel.liveSessions.isEmpty ? Color.secondary : Color.green).opacity(isDark ? 0.18 : 0.10))
                .clipShape(Capsule())
        }
    }

    private func featuredLatestCard(_ item: LatestMediaItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: posterURL(itemID: item.id)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    placeholderPoster
                }
            }
            .frame(width: 96, height: 136)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("本次焦点入库")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.mint)

                Text(item.name)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .lineLimit(3)

                Text("最新内容会直接影响首页热度和用户近期点击。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    miniBadge("海报", tint: .indigo)
                    miniBadge("新内容", tint: .mint)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.mint.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func spotlightCountCard(title: String, value: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .lineLimit(1)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(rowCardBackground)
    }

    private var liveSessionSpotlight: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("会话聚焦")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 0)

                Text(viewModel.liveSessions.isEmpty ? "暂无会话" : "实时更新")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if viewModel.liveSessions.isEmpty {
                emptyCard("当前没有正在播放的会话")
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.liveSessions.prefix(3)) { session in
                        liveSessionCompactRow(session)
                    }
                }
            }
        }
    }

    private func liveSessionCompactRow(_ session: LiveSession) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.mint)
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.nowPlayingItem?.name ?? "未知内容")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text("\(session.userName ?? "未知用户") · \(session.client ?? "未知客户端")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            miniBadge(session.deviceName ?? "设备", tint: .cyan)
        }
        .padding(12)
        .background(rowCardBackground)
    }

    private func miniBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(isDark ? 0.20 : 0.12))
            .clipShape(Capsule())
    }

    private func snapshotPill(title: String, value: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
            }

            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 136, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(isDark ? 0.32 : 0.18), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(tint.opacity(isDark ? 0.18 : 0.14))
                        .frame(width: 72, height: 72)
                        .blur(radius: 20)
                        .offset(x: -4, y: -10)
                }
                .shadow(color: tint.opacity(isDark ? 0.08 : 0.10), radius: 10, x: 0, y: 6)
        )
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
                LazyHStack(spacing: 12) {
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
                LazyHStack(spacing: 12) {
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
            .fill(.thinMaterial)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDark ? 0.05 : 0.42),
                                Color.white.opacity(0.01)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(
                        VStack(spacing: 0) {
                            Rectangle()
                                .frame(height: 54)
                            Spacer(minLength: 0)
                        }
                    )
            }
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.indigo.opacity(0.95), Color.cyan.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 74, height: 4)
                    .padding(.top, 12)
                    .padding(.leading, 14)
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.white.opacity(isDark ? 0.03 : 0.28))
                    .frame(width: 110, height: 110)
                    .blur(radius: 18)
                    .offset(x: 32, y: -36)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.16 : 0.05), radius: 10, x: 0, y: 6)
    }

    private var rowCardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.indigo.opacity(0.08), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color.white.opacity(isDark ? 0.08 : 0.32), Color.white.opacity(0.01)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
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
