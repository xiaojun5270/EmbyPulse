import SwiftUI

struct GapManagementView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = GapManagementViewModel()

    @State private var mode: GapManagementMode = .gaps
    @State private var displayLimit = 16
    @State private var pendingSeriesIgnore: GapSeriesItem?
    @State private var isConfigPresented = false
    @State private var configDraft = GapClientConfig()
    @State private var isSavingConfig = false

    @State private var isResolverPresented = false
    @State private var resolverType: GapResolverType = .single
    @State private var resolverSeries: GapSeriesItem?
    @State private var resolverSeason = 0
    @State private var resolverEpisodes: [Int] = []
    @State private var resolverSourceEpisode: GapEpisodeItem?
    @State private var resolverGenes: [String] = []
    @State private var resolverResults: [GapMPTorrentResult] = []
    @State private var resolverSelectedResultID: String?
    @State private var resolverTargetDescription: String = ""
    @State private var resolverManualKeyword: String = ""
    @State private var resolverSort: GapResolverSort = .score
    @State private var resolverPackFilter: GapResolverPackFilter = .all
    @State private var resolverTagFilter: String = "全部"
    @State private var isResolverLoading = false
    @State private var isResolverSubmitting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroPanel

                if let hint = viewModel.actionHint {
                    statusBanner(hint, tint: .green, symbol: "checkmark.circle.fill")
                }
                if let error = viewModel.errorMessage {
                    statusBanner(error, tint: .red, symbol: "exclamationmark.triangle.fill")
                }

                controlsSection

                if viewModel.scanState.isScanning {
                    progressSection
                }

                if mode == .gaps {
                    gapCardsSection
                } else {
                    recycleSection
                }
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("缺集管理")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.refresh(appState: appState)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isOperating || viewModel.isLoading || viewModel.scanState.isScanning)
            }
        }
        .task {
            await viewModel.loadInitial(appState: appState)
        }
        .refreshable {
            await viewModel.refresh(appState: appState)
        }
        .onDisappear {
            viewModel.stopBackgroundWork()
        }
        .sheet(isPresented: $isConfigPresented) {
            NavigationStack {
                configSheet
            }
        }
        .sheet(isPresented: $isResolverPresented, onDismiss: closeResolver) {
            NavigationStack {
                resolverSheet
            }
        }
        .confirmationDialog(
            "忽略整剧",
            isPresented: Binding(
                get: { pendingSeriesIgnore != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingSeriesIgnore = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let pendingSeriesIgnore {
                Button("忽略整剧", role: .destructive) {
                    let target = pendingSeriesIgnore
                    self.pendingSeriesIgnore = nil
                    Task {
                        await viewModel.ignoreSeries(appState: appState, series: target)
                    }
                }
                Button("取消", role: .cancel) {
                    self.pendingSeriesIgnore = nil
                }
            }
        } message: {
            if let pendingSeriesIgnore {
                Text("将把 \(pendingSeriesIgnore.seriesName) 的全部缺集标记为忽略。")
            }
        }
        .onChange(of: viewModel.sortedSeries.count) { count in
            if count < displayLimit {
                displayLimit = max(16, count)
            }
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("缺集雷达中心")
                        .font(ConsoleDesign.heroTitleFont)
                        .foregroundStyle(isDark ? .white : .primary)
                    Text("自动巡检、深度重扫、缺集回收站一体化管理")
                        .font(.footnote)
                        .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))
                }

                Spacer(minLength: 0)

                Image(systemName: viewModel.scanState.isScanning ? "dot.radiowaves.left.and.right" : "dot.scope")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConsoleDesign.heroBadgeForeground(isDark: isDark))
                    .padding(8)
                    .background(ConsoleDesign.heroBadgeBackground(isDark: isDark))
                    .clipShape(Circle())
            }

            Picker("模式", selection: $mode) {
                ForEach(GapManagementMode.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                heroPill(title: "剧集缺口", value: "\(viewModel.sortedSeries.count)")
                heroPill(title: "缺集总数", value: "\(viewModel.totalMissingEpisodes)")
                heroPill(title: "回收站", value: "\(viewModel.ignores.count)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.18, green: 0.32, blue: 0.43), Color(red: 0.12, green: 0.22, blue: 0.33)]
                    : [Color(red: 0.78, green: 0.91, blue: 1.0), Color(red: 0.86, green: 0.97, blue: 0.93)],
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

    private var controlsSection: some View {
        sectionCard(title: "巡检控制台", subtitle: "自动巡检、深度重扫与手动刷新", symbol: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("自动巡检")
                        .font(.subheadline.weight(.semibold))

                    Spacer(minLength: 10)

                    Toggle("", isOn: Binding(
                        get: { viewModel.autoScanEnabled },
                        set: { enabled in
                            Task {
                                await viewModel.updateAutoScan(appState: appState, enabled: enabled)
                            }
                        }
                    ))
                    .labelsHidden()
                    .disabled(viewModel.isOperating || viewModel.isLoading)
                }

                HStack(spacing: 10) {
                    Button {
                        Task {
                            await viewModel.startScan(appState: appState)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if viewModel.scanState.isScanning {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "dot.radiowaves.left.and.right")
                            }
                            Text(viewModel.scanState.isScanning ? "扫描中..." : "深度重扫")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(viewModel.scanState.isScanning || viewModel.isOperating)

                    Button {
                        Task {
                            await viewModel.refresh(appState: appState)
                        }
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isOperating || viewModel.isLoading)

                    Button {
                        Task {
                            await openConfigSheet()
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .frame(width: 18, height: 18)
                            .padding(8)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSavingConfig || viewModel.isOperating)
                }
            }
        }
    }

    private var progressSection: some View {
        sectionCard(title: "扫描进度", subtitle: "后台正在比对 TMDB 与本地媒体库", symbol: "gauge.with.dots.needle.67percent") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(viewModel.scanState.currentItem.isEmpty ? "正在扫描..." : viewModel.scanState.currentItem)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Text("\(viewModel.scanState.progress)/\(max(1, viewModel.scanState.total))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: viewModel.scanState.progressRate)
                    .tint(.indigo)
            }
        }
    }

    @ViewBuilder
    private var gapCardsSection: some View {
        if (viewModel.isLoading || viewModel.scanState.isScanning) && viewModel.sortedSeries.isEmpty {
            sectionCard(title: "缺集清单", subtitle: "首次同步中", symbol: "tray.and.arrow.down.fill") {
                ProgressView("正在同步缺集数据...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            }
        } else if viewModel.sortedSeries.isEmpty {
            sectionCard(title: "缺集清单", subtitle: "当前没有缺集记录", symbol: "checkmark.seal.fill") {
                emptyState(
                    icon: "checkmark.seal.fill",
                    title: "当前没有缺集记录",
                    subtitle: "可通过“深度重扫”重新检测媒体库"
                )
            }
        } else {
            sectionCard(
                title: "缺集卡片墙",
                subtitle: "按剧集聚合缺口，支持单集忽略与整剧忽略",
                symbol: "rectangle.grid.1x2.fill"
            ) {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.sortedSeries.prefix(displayLimit))) { series in
                        seriesCard(series)
                    }

                    if displayLimit < viewModel.sortedSeries.count {
                        Button {
                            displayLimit += 12
                        } label: {
                            Text("继续加载 \(viewModel.sortedSeries.count - displayLimit) 部剧集")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recycleSection: some View {
        sectionCard(title: "回收站", subtitle: "忽略记录与完结免检记录", symbol: "trash.fill") {
            if viewModel.isLoadingIgnores && viewModel.ignores.isEmpty {
                ProgressView("正在加载回收站...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            } else if viewModel.ignores.isEmpty {
                emptyState(
                    icon: "tray.fill",
                    title: "回收站为空",
                    subtitle: "忽略条目后会显示在这里"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.ignores) { item in
                        recycleRow(item)
                    }
                }
            }
        }
    }

    private func seriesCard(_ series: GapSeriesItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                AsyncImage(url: posterURL(path: series.poster)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        posterPlaceholder
                    }
                }
                .frame(width: 74, height: 108)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(series.seriesName)
                                .font(.headline)
                                .lineLimit(2)
                                .foregroundStyle(isDark ? Color.white.opacity(0.96) : Color.primary)

                            Text("缺集 \(series.missingCount) 处")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        Button {
                            pendingSeriesIgnore = series
                        } label: {
                            Image(systemName: "eye.slash.fill")
                                .font(.caption.weight(.semibold))
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(isDark ? 0.20 : 0.12))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("忽略整剧")
                    }

                    ForEach(series.groupedBySeason) { group in
                        seasonRow(series: series, group: group)
                    }
                }
            }

            if let embyURL = embyURL(path: series.embyURL) {
                Link(destination: embyURL) {
                    Label("在 Emby 中打开", systemImage: "safari")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    private func seasonRow(series: GapSeriesItem, group: GapSeasonGroup) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("S\(String(format: "%02d", group.season))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.indigo)
                    .frame(width: 34, alignment: .leading)

                Button {
                    Task {
                        await openResolverMulti(series: series, group: group)
                    }
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.caption2.weight(.bold))
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("一键补齐本季")
            }
            .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(group.episodes) { episode in
                        episodeChip(series: series, episode: episode)
                    }
                }
            }
        }
    }

    private func episodeChip(series: GapSeriesItem, episode: GapEpisodeItem) -> some View {
        let isProcessing = episode.status == 2
        return Button {
            Task {
                await openResolverSingle(series: series, episode: episode)
            }
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(isProcessing ? Color.blue : Color.red)
                    .frame(width: 6, height: 6)
                Text("E\(String(format: "%02d", episode.episode))")
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(isProcessing ? Color.blue : Color.red)
            .background(
                Capsule()
                    .fill((isProcessing ? Color.blue : Color.red).opacity(isDark ? 0.22 : 0.14))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("缺集 \(episode.codeText) 配型")
    }

    private func recycleRow(_ item: GapIgnoredItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(item.typeTitle)
                .font(.caption2.weight(.bold))
                .foregroundStyle(item.type == "perfect" ? Color.green : Color.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((item.type == "perfect" ? Color.green : Color.orange).opacity(isDark ? 0.24 : 0.14))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.seriesName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isDark ? Color.white.opacity(0.96) : Color.primary)
                    .lineLimit(1)
                Text(item.target)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button("恢复") {
                Task {
                    await viewModel.restoreIgnore(appState: appState, item: item)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .controlSize(.small)
            .disabled(viewModel.isOperating)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(ConsoleDesign.heroPillTitleColor(isDark: isDark))
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(ConsoleDesign.heroPillValueColor(isDark: isDark))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConsoleDesign.heroPillBackground(isDark: isDark))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statusBanner(_ text: String, tint: Color, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(text)
                .font(.footnote)
                .foregroundStyle(isDark ? Color.white.opacity(0.92) : Color.primary)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(isDark ? 0.22 : 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(0.34), lineWidth: 1)
                )
        )
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
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ConsoleDesign.sectionTitleFont)
                        .foregroundStyle(isDark ? Color.white.opacity(0.95) : Color.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            content()
        }
        .padding(ConsoleDesign.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .fill(isDark ? Color(red: 0.14, green: 0.16, blue: 0.20).opacity(0.95) : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isDark ? Color.white.opacity(0.95) : Color.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
    }

    private var configSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionCard(
                    title: "下载器截胡配置",
                    subtitle: "配置后季包可自动保留目标剧集文件",
                    symbol: "gearshape.2.fill"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("下载器类型", selection: $configDraft.clientType) {
                            Text("不启用").tag("")
                            Text("qBittorrent").tag("qbittorrent")
                            Text("Transmission").tag("transmission")
                        }
                        .pickerStyle(.menu)

                        if !configDraft.clientType.isEmpty {
                            TextField("下载器地址（例如 http://192.168.1.3:8080）", text: $configDraft.clientURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .textFieldStyle(.roundedBorder)

                            TextField("账号（可选）", text: $configDraft.clientUser)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .textFieldStyle(.roundedBorder)

                            SecureField("密码（可选）", text: $configDraft.clientPass)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("下载器配置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("关闭") {
                    isConfigPresented = false
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await saveConfig()
                    }
                } label: {
                    if isSavingConfig {
                        ProgressView()
                    } else {
                        Text("保存")
                    }
                }
                .disabled(isSavingConfig)
            }
        }
    }

    private var resolverSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionCard(
                    title: "资源配型",
                    subtitle: resolverTargetDescription.isEmpty ? "自动分析最佳匹配资源" : resolverTargetDescription,
                    symbol: "wand.and.stars"
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            TextField("自定义关键词（可选）", text: $resolverManualKeyword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .textFieldStyle(.roundedBorder)

                            Button {
                                Task {
                                    await refreshResolverSearch()
                                }
                            } label: {
                                if isResolverLoading {
                                    ProgressView()
                                        .padding(.horizontal, 4)
                                } else {
                                    Text("重搜")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isResolverSubmitting || isResolverLoading || resolverSeries == nil || resolverEpisodes.isEmpty)
                        }

                        if resolverGenes.isEmpty {
                            Text("未检测到风格特征，使用默认匹配策略")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(resolverGenes, id: \.self) { gene in
                                        Text(gene)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .fill(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                                            )
                                    }
                                }
                            }
                        }
                    }
                }

                sectionCard(
                    title: "候选资源",
                    subtitle: "选择最优结果后提交到 MP",
                    symbol: "externaldrive.badge.plus"
                ) {
                    if !resolverResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Picker("排序", selection: $resolverSort) {
                                    ForEach(GapResolverSort.allCases) { item in
                                        Text(item.title).tag(item)
                                    }
                                }
                                .pickerStyle(.menu)

                                Picker("资源类型", selection: $resolverPackFilter) {
                                    ForEach(GapResolverPackFilter.allCases) { item in
                                        Text(item.title).tag(item)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    filterTagChip("全部")
                                    ForEach(resolverAvailableTags, id: \.self) { tag in
                                        filterTagChip(tag)
                                    }
                                }
                            }
                        }
                    }

                    if isResolverLoading {
                        ProgressView("正在匹配资源...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 18)
                    } else if resolverResults.isEmpty {
                        emptyState(
                            icon: "tray.fill",
                            title: "未找到候选资源",
                            subtitle: "可尝试切换关键字后重新配型"
                        )
                    } else if filteredSortedResolverResults.isEmpty {
                        emptyState(
                            icon: "line.3.horizontal.decrease.circle",
                            title: "筛选后无结果",
                            subtitle: "可调整筛选条件或重置为“全部”"
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filteredSortedResolverResults) { result in
                                let selected = resolverSelectedResultID == result.id
                                Button {
                                    resolverSelectedResultID = result.id
                                } label: {
                                    resolverResultRow(result, selected: selected)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                sectionCard(
                    title: "动作",
                    subtitle: "提交下载或忽略单集",
                    symbol: "bolt.fill"
                ) {
                    HStack(spacing: 10) {
                        if resolverType == .single {
                            Button(role: .destructive) {
                                Task {
                                    await ignoreResolverEpisode()
                                }
                            } label: {
                                Label("忽略单集", systemImage: "eye.slash.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isResolverSubmitting || resolverSourceEpisode == nil)
                        }

                        Button {
                            Task {
                                await submitResolverDownload()
                            }
                        } label: {
                            if isResolverSubmitting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label("提交到 MP", systemImage: "paperplane.fill")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .disabled(isResolverSubmitting || isResolverLoading || selectedResolverResult == nil)
                    }
                }
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("配型中心")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("关闭") {
                    isResolverPresented = false
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await refreshResolverSearch()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isResolverSubmitting || isResolverLoading || resolverSeries == nil || resolverEpisodes.isEmpty)
            }
        }
        .onChange(of: resolverSort) { _ in
            ensureResolverSelection()
        }
        .onChange(of: resolverPackFilter) { _ in
            ensureResolverSelection()
        }
        .onChange(of: resolverTagFilter) { _ in
            ensureResolverSelection()
        }
    }

    private func resolverResultRow(_ result: GapMPTorrentResult, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.subheadline)
                    .foregroundStyle(selected ? Color.indigo : Color.secondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isDark ? Color.white.opacity(0.96) : Color.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(result.site)
                        Text(formatBytes(result.sizeBytes))
                        Text("做种 \(result.seeders)")
                        Text("Score \(result.matchScore)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    if !result.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(result.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.teal.opacity(isDark ? 0.24 : 0.14))
                                    )
                            }
                        }
                    }

                    if result.isPack {
                        Text("季包资源（可触发下载器截胡）")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selected
                    ? Color.indigo.opacity(isDark ? 0.25 : 0.14)
                    : (isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selected ? Color.indigo.opacity(0.55) : borderColor, lineWidth: 1)
                )
        )
    }

    private func filterTagChip(_ tag: String) -> some View {
        let selected = resolverTagFilter == tag
        return Button {
            resolverTagFilter = tag
        } label: {
            Text(tag)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .foregroundStyle(selected ? Color.white : (isDark ? Color.white.opacity(0.92) : Color.primary))
                .background(
                    Capsule()
                        .fill(selected ? Color.indigo : Color.secondary.opacity(isDark ? 0.22 : 0.12))
                )
        }
        .buttonStyle(.plain)
    }

    private var resolverAvailableTags: [String] {
        Array(Set(resolverResults.flatMap(\.tags))).sorted()
    }

    private var filteredSortedResolverResults: [GapMPTorrentResult] {
        var items = resolverResults

        switch resolverPackFilter {
        case .all:
            break
        case .single:
            items = items.filter { !$0.isPack }
        case .pack:
            items = items.filter { $0.isPack }
        }

        if resolverTagFilter != "全部" {
            let target = resolverTagFilter.lowercased()
            items = items.filter { result in
                result.tags.contains { $0.lowercased() == target }
            }
        }

        switch resolverSort {
        case .score:
            items.sort {
                if $0.matchScore == $1.matchScore {
                    return $0.seeders > $1.seeders
                }
                return $0.matchScore > $1.matchScore
            }
        case .seeders:
            items.sort {
                if $0.seeders == $1.seeders {
                    return $0.matchScore > $1.matchScore
                }
                return $0.seeders > $1.seeders
            }
        case .size:
            items.sort {
                if $0.sizeBytes == $1.sizeBytes {
                    return $0.matchScore > $1.matchScore
                }
                return $0.sizeBytes > $1.sizeBytes
            }
        }

        return items
    }

    private var selectedResolverResult: GapMPTorrentResult? {
        if let selectedID = resolverSelectedResultID {
            return filteredSortedResolverResults.first(where: { $0.id == selectedID })
        }
        return filteredSortedResolverResults.first
    }

    private func ensureResolverSelection() {
        guard !filteredSortedResolverResults.isEmpty else {
            resolverSelectedResultID = nil
            return
        }
        if let selectedID = resolverSelectedResultID,
           filteredSortedResolverResults.contains(where: { $0.id == selectedID }) {
            return
        }
        resolverSelectedResultID = filteredSortedResolverResults.first?.id
    }

    private func openConfigSheet() async {
        if let config = await viewModel.fetchConfig(appState: appState) {
            configDraft = config
        } else {
            configDraft = GapClientConfig()
        }
        isConfigPresented = true
    }

    private func saveConfig() async {
        isSavingConfig = true
        let saved = await viewModel.saveConfig(appState: appState, config: configDraft)
        isSavingConfig = false
        if saved {
            isConfigPresented = false
        }
    }

    private func openResolverSingle(series: GapSeriesItem, episode: GapEpisodeItem) async {
        let desc = "\(series.seriesName) \(episode.codeText)"
        await openResolver(
            series: series,
            season: episode.season,
            episodes: [episode.episode],
            sourceEpisode: episode,
            type: .single,
            targetDescription: desc
        )
    }

    private func openResolverMulti(series: GapSeriesItem, group: GapSeasonGroup) async {
        let targetEpisodes = group.episodes
            .filter { $0.status == 0 || $0.status == 2 }
            .map(\.episode)
        guard !targetEpisodes.isEmpty else { return }

        let episodeText = targetEpisodes.map { String(format: "%02d", $0) }.joined(separator: ", ")
        let desc = "\(series.seriesName) S\(String(format: "%02d", group.season)) 批量补齐 [\(episodeText)]"
        await openResolver(
            series: series,
            season: group.season,
            episodes: targetEpisodes,
            sourceEpisode: nil,
            type: .multi,
            targetDescription: desc
        )
    }

    private func openResolver(
        series: GapSeriesItem,
        season: Int,
        episodes: [Int],
        sourceEpisode: GapEpisodeItem?,
        type: GapResolverType,
        targetDescription: String
    ) async {
        resolverSeries = series
        resolverSeason = season
        resolverEpisodes = episodes
        resolverSourceEpisode = sourceEpisode
        resolverType = type
        resolverTargetDescription = targetDescription
        resolverManualKeyword = series.seriesName
        resolverSort = .score
        resolverPackFilter = .all
        resolverTagFilter = "全部"
        resolverGenes = []
        resolverResults = []
        resolverSelectedResultID = nil
        isResolverLoading = true
        isResolverSubmitting = false
        isResolverPresented = true

        if let data = await viewModel.searchResources(
            appState: appState,
            series: series,
            season: season,
            episodes: episodes,
            customKeyword: manualKeywordForSearch
        ) {
            resolverGenes = data.genes
            resolverResults = data.results
            ensureResolverSelection()
        }

        isResolverLoading = false
    }

    private func refreshResolverSearch() async {
        guard let series = resolverSeries, !resolverEpisodes.isEmpty else { return }
        isResolverLoading = true
        if let data = await viewModel.searchResources(
            appState: appState,
            series: series,
            season: resolverSeason,
            episodes: resolverEpisodes,
            customKeyword: manualKeywordForSearch
        ) {
            resolverGenes = data.genes
            resolverResults = data.results
            ensureResolverSelection()
        }
        isResolverLoading = false
    }

    private func submitResolverDownload() async {
        guard let selected = selectedResolverResult, let series = resolverSeries else { return }
        isResolverSubmitting = true
        let ok = await viewModel.submitDownload(
            appState: appState,
            series: series,
            season: resolverSeason,
            episodes: resolverEpisodes,
            selected: selected
        )
        isResolverSubmitting = false

        if ok {
            isResolverPresented = false
            closeResolver()
            await viewModel.refresh(appState: appState)
        }
    }

    private func ignoreResolverEpisode() async {
        guard
            let series = resolverSeries,
            let episode = resolverSourceEpisode
        else { return }

        isResolverSubmitting = true
        await viewModel.ignoreEpisode(appState: appState, series: series, episode: episode)
        isResolverSubmitting = false
        isResolverPresented = false
        closeResolver()
    }

    private func closeResolver() {
        resolverSeries = nil
        resolverSeason = 0
        resolverEpisodes = []
        resolverSourceEpisode = nil
        resolverGenes = []
        resolverResults = []
        resolverSelectedResultID = nil
        resolverTargetDescription = ""
        resolverManualKeyword = ""
        resolverSort = .score
        resolverPackFilter = .all
        resolverTagFilter = "全部"
        isResolverLoading = false
        isResolverSubmitting = false
        resolverType = .single
    }

    private var manualKeywordForSearch: String? {
        let value = resolverManualKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: max(0, Int64(bytes)))
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

    private var borderColor: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var posterPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: isDark
                    ? [Color.white.opacity(0.12), Color.white.opacity(0.08)]
                    : [Color.indigo.opacity(0.16), Color.cyan.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "film.stack")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func posterURL(path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        let base = appState.environment.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        return URL(string: base + normalizedPath)
    }

    private func embyURL(path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        let base = appState.environment.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        return URL(string: base + normalizedPath)
    }

    private var isDark: Bool {
        appState.appearanceMode == .dark
    }
}

private enum GapManagementMode: String, CaseIterable, Identifiable {
    case gaps
    case recycle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gaps:
            return "缺集清单"
        case .recycle:
            return "回收站"
        }
    }
}

private enum GapResolverType {
    case single
    case multi
}

private enum GapResolverSort: String, CaseIterable, Identifiable {
    case score
    case seeders
    case size

    var id: String { rawValue }

    var title: String {
        switch self {
        case .score:
            return "匹配分"
        case .seeders:
            return "做种数"
        case .size:
            return "体积"
        }
    }
}

private enum GapResolverPackFilter: String, CaseIterable, Identifiable {
    case all
    case single
    case pack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .single:
            return "单集"
        case .pack:
            return "季包"
        }
    }
}
