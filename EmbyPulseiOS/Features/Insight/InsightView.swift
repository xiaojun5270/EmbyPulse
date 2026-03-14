import SwiftUI

struct InsightView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = InsightViewModel()
    @State private var mode: InsightMode = .quality

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroPanel

                if let hint = viewModel.actionHint {
                    statusBanner(hint, tint: .green)
                }
                if let error = viewModel.errorMessage {
                    statusBanner(error, tint: .red)
                }

                if mode == .quality {
                    qualityBody
                } else {
                    recycleBody
                }
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("质量盘点")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        if mode == .quality {
                            await viewModel.loadQuality(appState: appState, forceRefresh: false)
                        } else {
                            await viewModel.loadIgnores(appState: appState)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isOperating || viewModel.isLoadingQuality || viewModel.isLoadingIgnores)
            }
        }
        .task {
            await viewModel.loadInitial(appState: appState)
        }
        .refreshable {
            if mode == .quality {
                await viewModel.loadQuality(appState: appState, forceRefresh: false)
            } else {
                await viewModel.loadIgnores(appState: appState)
            }
        }
        .onChange(of: mode) { newValue in
            if newValue == .recycle {
                Task { await viewModel.loadIgnores(appState: appState) }
            }
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("质量洞察中心")
                .font(ConsoleDesign.heroTitleFont)
                .foregroundStyle(isDark ? .white : .primary)

            Text(mode == .quality ? "分辨率矩阵、动态范围、编码结构一屏总览" : "忽略项回收站与批量恢复管理")
                .font(.footnote)
                .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))

            Picker("模块", selection: $mode) {
                ForEach(InsightMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .quality {
                HStack(spacing: 8) {
                    heroPill(title: "总片量", value: "\(viewModel.qualityStats?.totalCount ?? 0)")
                    heroPill(title: "当前分类", value: "\(viewModel.currentItems.count)")
                    heroPill(title: "已选", value: "\(viewModel.selectedMovieIDs.count)")
                }
            } else {
                HStack(spacing: 8) {
                    heroPill(title: "回收站条目", value: "\(viewModel.ignores.count)")
                    heroPill(title: "已选恢复", value: "\(viewModel.selectedIgnoreIDs.count)")
                    heroPill(title: "状态", value: viewModel.isLoadingIgnores ? "同步中" : "就绪")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.21, green: 0.28, blue: 0.41), Color(red: 0.16, green: 0.22, blue: 0.33)]
                    : [Color(red: 0.79, green: 0.90, blue: 1.0), Color(red: 0.88, green: 0.98, blue: 0.94)],
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
                .lineLimit(1)
                .foregroundStyle(ConsoleDesign.heroPillValueColor(isDark: isDark))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConsoleDesign.heroPillBackground(isDark: isDark))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var qualityBody: some View {
        sectionCard(
            title: "质量快照",
            subtitle: "扫描状态与关键指标",
            symbol: "checkmark.shield.fill"
        ) {
            snapshotSection
        }

        sectionCard(
            title: "分辨率矩阵",
            subtitle: "4K 到 SD 的内容分布",
            symbol: "square.grid.2x2.fill"
        ) {
            resolutionMatrixSection
        }

        sectionCard(
            title: "光影与动态范围",
            subtitle: "杜比视界、HDR10、SDR 分层",
            symbol: "sparkles.tv.fill"
        ) {
            dynamicRangeSection
        }

        sectionCard(
            title: "编码结构",
            subtitle: "HEVC / H264 / AV1 与其他编码",
            symbol: "cpu.fill"
        ) {
            codecSection
        }

        sectionCard(
            title: "当前分类清单",
            subtitle: "支持批量忽略与海报辅助识别",
            symbol: "list.bullet.rectangle.fill"
        ) {
            listSection
        }
    }

    @ViewBuilder
    private var snapshotSection: some View {
        let scanText = viewModel.qualityStats?.scanTime?.isEmpty == false ? (viewModel.qualityStats?.scanTime ?? "未知") : "尚未扫描"
        let totalCount = viewModel.qualityStats?.totalCount ?? 0
        let selectedCount = viewModel.selectedMovieIDs.count
        let currentCount = viewModel.currentItems.count

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            summaryMetric(title: "总片量", value: "\(totalCount)", tint: .indigo, icon: "shippingbox.fill")
            summaryMetric(title: "当前分类", value: "\(currentCount)", tint: .blue, icon: "square.stack.3d.up.fill")
            summaryMetric(title: "已选条目", value: "\(selectedCount)", tint: .teal, icon: "checkmark.circle.fill")
            summaryMetric(title: "扫描时间", value: scanText, tint: .orange, icon: "clock.fill")
        }

        HStack(spacing: 10) {
            Button {
                Task { await viewModel.loadQuality(appState: appState, forceRefresh: false) }
            } label: {
                if viewModel.isLoadingQuality {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("刷新缓存")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoadingQuality || viewModel.isOperating)

            Button {
                Task { await viewModel.loadQuality(appState: appState, forceRefresh: true) }
            } label: {
                Text("深度重扫")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoadingQuality || viewModel.isOperating)
        }
    }

    private var resolutionMatrixSection: some View {
        let cards: [InsightCategory] = [.fourK, .fullHD, .hd, .sd]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(cards) { category in
                matrixCard(for: category)
            }
        }
    }

    private var dynamicRangeSection: some View {
        let cards: [InsightCategory] = [.dolbyVision, .hdr10, .sdr]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(cards) { category in
                matrixCard(for: category)
            }
        }
    }

    private var codecSection: some View {
        let cards: [InsightCategory] = [.hevc, .h264, .av1, .otherCodec]
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(cards) { category in
                    let selected = viewModel.selectedCategory == category
                    Button {
                        viewModel.switchCategory(category)
                    } label: {
                        Text("\(category.title) \(count(for: category))")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .foregroundStyle(selected ? Color.white : Color.primary)
                            .background(
                                selected
                                    ? Color.indigo
                                    : (isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.72))
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var listSection: some View {
        if viewModel.isLoadingQuality && viewModel.currentItems.isEmpty {
            ProgressView("加载中...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 18)
        } else if viewModel.currentItems.isEmpty {
            Text("当前分类暂无条目")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
        } else {
            HStack(spacing: 10) {
                Button(viewModel.selectedMovieIDs.count == viewModel.currentItems.count ? "取消全选" : "全选当前分类") {
                    viewModel.toggleSelectAllCurrentItems()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("批量忽略 \(viewModel.selectedMovieIDs.count)") {
                    Task { await viewModel.ignoreSelectedItems(appState: appState) }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.selectedMovieIDs.isEmpty || viewModel.isOperating)
            }

            VStack(spacing: 8) {
                ForEach(viewModel.currentItems) { item in
                    InsightMovieRow(
                        item: item,
                        isSelected: viewModel.selectedMovieIDs.contains(item.id),
                        baseURL: appState.environment.baseURL,
                        onToggleSelection: {
                            viewModel.toggleMovieSelection(id: item.id)
                        }
                    )
                }
            }
        }
    }

    private var recycleBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionCard(
                title: "忽略回收站",
                subtitle: "支持批量恢复到质量列表",
                symbol: "arrow.uturn.left.circle.fill"
            ) {
                HStack(spacing: 10) {
                    Button(viewModel.selectedIgnoreIDs.count == viewModel.ignores.count ? "取消全选" : "全选") {
                        viewModel.toggleSelectAllIgnores()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.ignores.isEmpty)

                    Spacer()

                    Button("批量恢复 \(viewModel.selectedIgnoreIDs.count)") {
                        Task { await viewModel.restoreSelectedIgnores(appState: appState) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.selectedIgnoreIDs.isEmpty || viewModel.isOperating)
                }
            }

            if viewModel.isLoadingIgnores && viewModel.ignores.isEmpty {
                sectionCard(
                    title: "条目列表",
                    subtitle: "正在同步回收站",
                    symbol: "tray.and.arrow.down.fill"
                ) {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 18)
                }
            } else if viewModel.ignores.isEmpty {
                sectionCard(
                    title: "条目列表",
                    subtitle: "当前没有可恢复项",
                    symbol: "tray.fill"
                ) {
                    Text("回收站为空")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            } else {
                sectionCard(
                    title: "条目列表",
                    subtitle: "共 \(viewModel.ignores.count) 项",
                    symbol: "tray.full.fill"
                ) {
                    VStack(spacing: 8) {
                        ForEach(viewModel.ignores) { item in
                            InsightIgnoreRow(
                                item: item,
                                isSelected: viewModel.selectedIgnoreIDs.contains(item.itemID),
                                onToggleSelection: {
                                    viewModel.toggleIgnoreSelection(id: item.itemID)
                                }
                            )
                        }
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

    private func statusBanner(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func summaryMetric(title: String, value: String, tint: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(isDark ? 0.18 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func matrixCard(for category: InsightCategory) -> some View {
        let selected = viewModel.selectedCategory == category
        let count = count(for: category)
        let total = max(viewModel.qualityStats?.totalCount ?? 0, 1)
        let ratio = min(Double(count) / Double(total), 1.0)

        return Button {
            viewModel.switchCategory(category)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(category.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selected ? .indigo : .secondary)
                Text("\(count)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(selected ? .indigo : .primary)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.16))
                        Capsule()
                            .fill(selected ? Color.indigo : Color.blue.opacity(0.52))
                            .frame(width: proxy.size.width * ratio)
                    }
                }
                .frame(height: 5)

                Text("\(Int(ratio * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.indigo.opacity(0.12) : rowSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.indigo.opacity(0.35) : Color.gray.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func count(for category: InsightCategory) -> Int {
        viewModel.qualityStats?.movies.count(for: category) ?? 0
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

private struct InsightMovieRow: View {
    @EnvironmentObject private var appState: AppState
    let item: InsightMovieItem
    let isSelected: Bool
    let baseURL: String
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.red : Color.secondary)
                    .font(.headline)
            }
            .buttonStyle(.plain)

            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(rowSurface)
                        Image(systemName: "film.stack")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 48, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if !item.year.isEmpty {
                        Text(item.year)
                    }
                    Text(item.resolution)
                        .foregroundStyle(.blue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !item.path.isEmpty {
                    Text(item.path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(rowSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.red.opacity(0.32) : Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private var rowSurface: Color {
        appState.appearanceMode == .dark
            ? Color(red: 0.20, green: 0.22, blue: 0.26)
            : Color.white.opacity(0.84)
    }

    private var posterURL: URL? {
        guard !item.id.isEmpty else { return nil }
        var normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.hasPrefix("http://") && !normalized.hasPrefix("https://") {
            normalized = "http://" + normalized
        }
        if normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return URL(string: "\(normalized)/api/proxy/smart_image?item_id=\(item.id)&type=Primary")
    }
}

private struct InsightIgnoreRow: View {
    @EnvironmentObject private var appState: AppState
    let item: InsightIgnoreItem
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.indigo : Color.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text("ID: \(item.itemID)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let ignoredAt = item.ignoredAt, !ignoredAt.isEmpty {
                    Text(ignoredAt.replacingOccurrences(of: "T", with: " ").prefix(16))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(rowSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.indigo.opacity(0.32) : Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private var rowSurface: Color {
        appState.appearanceMode == .dark
            ? Color(red: 0.20, green: 0.22, blue: 0.26)
            : Color.white.opacity(0.84)
    }
}

private enum InsightMode: String, CaseIterable, Identifiable {
    case quality
    case recycle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quality:
            return "质量盘点"
        case .recycle:
            return "忽略回收站"
        }
    }
}
