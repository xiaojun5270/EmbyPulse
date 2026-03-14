import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 14) {
                heroCard
                momentumStrip

                if let warning = viewModel.warningMessage {
                    warningLabel(warning)
                }

                if let error = viewModel.errorMessage {
                    errorLabel(error)
                }

                sectionCard(
                    title: "Overview",
                    subtitle: "Library size, activity and runtime status",
                    symbol: "rectangle.grid.2x2.fill"
                ) {
                    overviewContent
                }

                if hasLibrarySection {
                    sectionCard(
                        title: "Libraries",
                        subtitle: "Common libraries and content types",
                        symbol: "books.vertical.fill"
                    ) {
                        libraryViewsContent
                    }
                }

                if hasActivitySection {
                    sectionCard(
                        title: "Recent Activity",
                        subtitle: "Latest arrivals and recent playback",
                        symbol: "sparkles.rectangle.stack.fill"
                    ) {
                        activityContent
                    }
                }

                if hasInsightSection {
                    sectionCard(
                        title: "Trend",
                        subtitle: "Playback trend and active users",
                        symbol: "chart.line.uptrend.xyaxis"
                    ) {
                        insightContent
                    }
                }

                sectionCard(
                    title: "Live Sessions",
                    subtitle: "Current sessions and playback devices",
                    symbol: "dot.radiowaves.left.and.right"
                ) {
                    realtimeContent
                }
            }
            .padding(.horizontal, ConsoleDesign.pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .coordinateSpace(name: "dashboard-scroll")
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
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
                        Text("Emby Pulse Console")
                            .font(ConsoleDesign.heroTitleFont)
                            .foregroundStyle(.white)

                        Text("Live status, playback trend and media operations")
                            .font(.footnote)
                            .foregroundStyle(Color.white.opacity(0.80))

                        HStack(spacing: 8) {
                            heroTag("Home")
                            heroTag(viewModel.isLoading ? "Refreshing" : "Light Layout")
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
                    heroMetric(title: "Total Plays", value: "\(viewModel.dashboard?.totalPlays ?? 0)")
                    heroMetric(title: "Active Users", value: "\(viewModel.dashboard?.activeUsers ?? 0)")
                    heroMetric(title: "Live Sessions", value: "\(viewModel.liveSessions.count)")
                }

                HStack(spacing: 10) {
                    Label("Updated \(lastUpdatedText)", systemImage: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.78))

                    Spacer(minLength: 0)

                    Text(viewModel.liveSessions.isEmpty ? "No active session" : "\(viewModel.liveSessions.count) active sessions")
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
            .shadow(color: Color.black.opacity(isDark ? 0.22 : 0.10), radius: 16, x: 0, y: 12)
            .offset(y: minY < 0 ? minY * 0.10 : 0)
            .scaleEffect(stretch > 0 ? 1 + stretch / 1400 : 1, anchor: .top)
            .preference(key: DashboardChromeProgressPreferenceKey.self, value: collapseProgress(for: minY))
        }
        .frame(height: 194)
    }

    private var heroBackground: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.17, green: 0.25, blue: 0.40), Color(red: 0.11, green: 0.18, blue: 0.30)]
                    : [Color(red: 0.24, green: 0.47, blue: 0.90), Color(red: 0.09, green: 0.69, blue: 0.73)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 150, height: 150)
                .blur(radius: 18)
                .offset(x: 24, y: -34)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(14))
                .offset(x: 34, y: 72)
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
                .foregroundStyle(Color.white.opacity(0.74))

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
                snapshotPill(title: "Items", value: "\(totalLibraryItems)", subtitle: "Library", tint: .indigo)
                snapshotPill(title: "Trend", value: String(format: "%.1f h", totalTrendHours), subtitle: "Recent hours", tint: .cyan)
                snapshotPill(title: "Latest", value: "\(viewModel.latestMedia.count)", subtitle: "New content", tint: .mint)
                snapshotPill(title: "Live", value: "\(viewModel.liveSessions.count)", subtitle: "Active now", tint: .orange)
            }
            .padding(.horizontal, 1)
        }
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 126, alignment: .leading)
        .background(rowCardBackground)
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            mediaCapacityContent

            Divider().overlay(Color.primary.opacity(0.06))

            coreMetricsContent
        }
    }

    private var mediaCapacityContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            dashboardPill(title: "Total Items", value: "\(totalLibraryItems)", tint: .indigo)
            dashboardPill(title: "Movies", value: "\(viewModel.dashboard?.library.movie ?? 0)", tint: .blue)
            dashboardPill(title: "Series", value: "\(viewModel.dashboard?.library.series ?? 0)", tint: .mint)
            dashboardPill(title: "Episodes", value: "\(viewModel.dashboard?.library.episode ?? 0)", tint: .orange)
        }
    }

    private var coreMetricsContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            dashboardMetricCard("Total Plays", "\(viewModel.dashboard?.totalPlays ?? 0)", "play.circle.fill", .indigo)
            dashboardMetricCard("Active Users", "\(viewModel.dashboard?.activeUsers ?? 0)", "person.2.fill", .blue)
            dashboardMetricCard("Duration", formattedHours(from: viewModel.dashboard?.totalDuration ?? 0), "clock.fill", .mint)
            dashboardMetricCard("Live Sessions", "\(viewModel.liveSessions.count)", "dot.radiowaves.left.and.right", .orange)
        }
    }

    private var activityContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !viewModel.latestMedia.isEmpty {
                moduleTitle("Latest Arrivals", systemImage: "square.stack.3d.down.right.fill")
                latestMediaContent
            }

            if !viewModel.latestMedia.isEmpty && !viewModel.recentActivities.isEmpty {
                Divider().overlay(Color.primary.opacity(0.06))
            }

            if !viewModel.recentActivities.isEmpty {
                moduleTitle("Recent Playback", systemImage: "play.rectangle.on.rectangle.fill")
                recentPlaybackContent
            }
        }
    }

    @ViewBuilder
    private var libraryViewsContent: some View {
        if viewModel.libraries.isEmpty {
            emptyCard("No library data")
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
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(viewModel.latestMedia.prefix(8)) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        AsyncImage(url: posterURL(itemID: item.id)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                placeholderPoster
                            }
                        }
                        .frame(width: 120, height: 172)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text(item.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .frame(width: 120, alignment: .leading)
                    }
                    .padding(10)
                    .background(rowCardBackground)
                }
            }
        }
    }

    @ViewBuilder
    private var recentPlaybackContent: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.recentActivities.prefix(4)) { item in
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

    private var insightContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !viewModel.trendPoints.isEmpty {
                moduleTitle("Playback Trend", systemImage: "chart.bar.xaxis.ascending")
                trendTrackingContent
            }

            if !viewModel.trendPoints.isEmpty && !viewModel.platinumUsers.isEmpty {
                Divider().overlay(Color.primary.opacity(0.06))
            }

            if !viewModel.platinumUsers.isEmpty {
                moduleTitle("Top Users", systemImage: "trophy.fill")
                platinumRankingContent
            }
        }
    }

    @ViewBuilder
    private var trendTrackingContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Chart(viewModel.trendPoints) { point in
                BarMark(
                    x: .value("Date", point.label),
                    y: .value("Hours", point.hours)
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
            .frame(height: 206)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6))
            }

            HStack(spacing: 8) {
                dashboardPill(title: "Hours", value: String(format: "%.1f h", totalTrendHours), tint: .cyan)
                dashboardPill(title: "Points", value: "\(viewModel.trendPoints.count)", tint: .indigo)
            }
        }
        .padding(12)
        .background(rowCardBackground)
    }

    @ViewBuilder
    private var platinumRankingContent: some View {
        HStack(spacing: 8) {
            periodChip(title: "Day", period: .day)
            periodChip(title: "Week", period: .week)
            periodChip(title: "Month", period: .month)
            periodChip(title: "All", period: .all)
        }

        VStack(spacing: 8) {
            ForEach(Array(viewModel.platinumUsers.prefix(4).enumerated()), id: \.element.id) { index, item in
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

                        Text("Plays \(item.plays) · \(String(format: "%.1f", item.totalHours)) h")
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

    @ViewBuilder
    private var realtimeContent: some View {
        if viewModel.liveSessions.isEmpty {
            emptyCard("No live session")
        } else {
            VStack(spacing: 8) {
                ForEach(viewModel.liveSessions.prefix(4)) { session in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.mint)
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.nowPlayingItem?.name ?? "Unknown Content")
                                .font(.subheadline.weight(.semibold))

                            Text("\(session.userName ?? "Unknown User") · \(session.client ?? "Unknown Client") · \(session.deviceName ?? "Unknown Device")")
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

    private func moduleTitle(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private var hasLibrarySection: Bool {
        !viewModel.libraries.isEmpty
    }

    private var hasActivitySection: Bool {
        !viewModel.latestMedia.isEmpty || !viewModel.recentActivities.isEmpty
    }

    private var hasInsightSection: Bool {
        !viewModel.trendPoints.isEmpty || !viewModel.platinumUsers.isEmpty
    }

    private var totalLibraryItems: Int {
        let library = viewModel.dashboard?.library
        return (library?.movie ?? 0) + (library?.series ?? 0) + (library?.episode ?? 0)
    }

    private var totalTrendHours: Double {
        viewModel.trendPoints.reduce(0.0) { $0 + $1.hours }
    }

    private var lastUpdatedText: String {
        guard let date = viewModel.lastUpdatedAt else { return "Never" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func collapseProgress(for offset: CGFloat) -> CGFloat {
        min(max((-offset - 8) / 140, 0), 1)
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
                    .background(Color.indigo.opacity(isDark ? 0.24 : 0.12))
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
        .padding(13)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDark ? 0.12 : 0.05), radius: 10, x: 0, y: 6)
    }

    private var rowCardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.indigo.opacity(0.08), lineWidth: 1)
            )
    }

    private var placeholderPoster: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDark ? Color(red: 0.18, green: 0.20, blue: 0.24) : Color.white.opacity(0.8))

            Image(systemName: "film.stack")
                .foregroundStyle(.secondary)
        }
    }

    private func dashboardMetricCard(_ title: String, _ value: String, _ symbol: String, _ tint: Color) -> some View {
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
        .background(tint.opacity(isDark ? 0.22 : 0.10))
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
            .background(Color.red.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formattedHours(from seconds: Int) -> String {
        let hours = Double(seconds) / 3600.0
        return String(format: "%.1f h", hours)
    }

    private func collectionTypeTitle(_ raw: String) -> String {
        switch raw.lowercased() {
        case "movies", "movie":
            return "Movie Library"
        case "tvshows", "tvshow", "series":
            return "Series Library"
        case "music":
            return "Music Library"
        default:
            return raw.isEmpty ? "Unknown Type" : raw
        }
    }

    private func itemType(_ raw: String) -> String {
        switch raw.lowercased() {
        case "movie":
            return "Movie"
        case "episode":
            return "Episode"
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
