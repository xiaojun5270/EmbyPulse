import SwiftUI

struct RequestsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = RequestsViewModel()
    @State private var filter: RequestFilter = .pending
    @State private var rejectTarget: ManagedRequest?
    @State private var rejectReason = ""
    @State private var batchRejectReason = ""
    @State private var isShowingBatchRejectSheet = false

    private var filteredRequests: [ManagedRequest] {
        switch filter {
        case .all:
            return viewModel.requests
        default:
            return viewModel.requests.filter { filter.matches(status: $0.status) }
        }
    }

    private var selectedFilteredCount: Int {
        viewModel.selectedCount(in: filteredRequests)
    }

    private var allFilteredSelected: Bool {
        !filteredRequests.isEmpty && selectedFilteredCount == filteredRequests.count
    }

    private var pendingCount: Int {
        viewModel.requests.filter { $0.status == ManagedRequestStatus.pending.rawValue }.count
    }

    private var processingCount: Int {
        viewModel.requests.filter {
            $0.status == ManagedRequestStatus.approved.rawValue || $0.status == ManagedRequestStatus.manual.rawValue
        }.count
    }

    private var doneCount: Int {
        viewModel.requests.filter {
            $0.status == ManagedRequestStatus.done.rawValue || $0.status == ManagedRequestStatus.rejected.rawValue
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroPanel
                filterSection

                if let actionHint = viewModel.actionHint {
                    statusBanner(actionHint, tint: .green)
                }
                if let error = viewModel.errorMessage {
                    statusBanner(error, tint: .red)
                }

                if !filteredRequests.isEmpty {
                    batchSection
                }

                requestListSection
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("求片工单")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if viewModel.isLoading && viewModel.requests.isEmpty {
                ProgressView("加载中...")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.load(appState: appState) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.load(appState: appState)
        }
        .refreshable {
            await viewModel.load(appState: appState)
        }
        .sheet(isPresented: $isShowingBatchRejectSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                        sheetHero(
                            title: "批量拒绝",
                            subtitle: "将拒绝当前筛选中已选的 \(selectedFilteredCount) 项工单",
                            symbol: "xmark.shield.fill"
                        )

                        sheetCard(title: "拒绝原因", symbol: "pencil.and.list.clipboard") {
                            TextField("请输入原因", text: $batchRejectReason)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(ConsoleDesign.pagePadding)
                }
                .background(pageGradient.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            isShowingBatchRejectSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确认") {
                            let reason = batchRejectReason.trimmingCharacters(in: .whitespacesAndNewlines)
                            Task {
                                await viewModel.performBatch(
                                    action: .reject,
                                    in: filteredRequests,
                                    rejectReason: reason.isEmpty ? "暂不处理" : reason,
                                    appState: appState
                                )
                                isShowingBatchRejectSheet = false
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $rejectTarget) { request in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                        sheetHero(
                            title: "拒绝工单",
                            subtitle: "填写拒绝原因并提交",
                            symbol: "xmark.seal.fill"
                        )

                        sheetCard(title: "工单信息", symbol: "doc.text.fill") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(request.title)
                                    .font(.headline)
                                    .lineLimit(3)
                                Text("TMDB: \(request.tmdbID) · Season \(request.season)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        sheetCard(title: "拒绝原因", symbol: "text.badge.xmark") {
                            TextField("请输入原因", text: $rejectReason)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(ConsoleDesign.pagePadding)
                }
                .background(pageGradient.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            rejectTarget = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确认") {
                            let reason = rejectReason.trimmingCharacters(in: .whitespacesAndNewlines)
                            Task {
                                await viewModel.perform(
                                    action: .reject,
                                    request: request,
                                    rejectReason: reason.isEmpty ? "暂不处理" : reason,
                                    appState: appState
                                )
                                rejectTarget = nil
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("工单调度中心")
                        .font(ConsoleDesign.heroTitleFont)
                        .foregroundStyle(isDark ? .white : .primary)
                    Text("筛选、批量执行与状态追踪")
                        .font(.footnote)
                        .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))
                }

                Spacer(minLength: 0)

                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConsoleDesign.heroBadgeForeground(isDark: isDark))
                    .padding(8)
                    .background(ConsoleDesign.heroBadgeBackground(isDark: isDark))
                    .clipShape(Circle())
            }

            HStack(spacing: 8) {
                heroPill(title: "待处理", value: "\(pendingCount)")
                heroPill(title: "处理中", value: "\(processingCount)")
                heroPill(title: "已结束", value: "\(doneCount)")
                heroPill(title: "筛选后", value: "\(filteredRequests.count)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.21, green: 0.28, blue: 0.41), Color(red: 0.17, green: 0.22, blue: 0.33)]
                    : [Color(red: 0.80, green: 0.90, blue: 1.0), Color(red: 0.88, green: 0.98, blue: 0.95)],
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
            title: "筛选条件",
            subtitle: "切换工单状态范围",
            symbol: "line.3.horizontal.decrease.circle.fill"
        ) {
            Picker("状态", selection: $filter) {
                ForEach(RequestFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var batchSection: some View {
        sectionCard(
            title: "批量操作",
            subtitle: "已选 \(selectedFilteredCount) / \(filteredRequests.count)",
            symbol: "checklist"
        ) {
            HStack {
                Text("当前筛选：\(filter.title)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(allFilteredSelected ? "取消全选" : "全选当前筛选") {
                    viewModel.toggleSelectAll(in: filteredRequests)
                }
                .buttonStyle(.bordered)
            }

            if selectedFilteredCount > 0 {
                HStack(spacing: 10) {
                    Menu {
                        Button("推送 MP") { Task { await performBatchAction(.approve) } }
                        Button("手动接单") { Task { await performBatchAction(.manual) } }
                        Button("标记完成") { Task { await performBatchAction(.finish) } }
                        Button("拒绝并写原因") {
                            batchRejectReason = ""
                            isShowingBatchRejectSheet = true
                        }
                        Button("删除", role: .destructive) { Task { await performBatchAction(.delete) } }
                    } label: {
                        Label("批量执行", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("批量拒绝") {
                        batchRejectReason = ""
                        isShowingBatchRejectSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)

                    if viewModel.isBatchProcessing {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
        }
    }

    private var requestListSection: some View {
        sectionCard(
            title: "工单列表",
            subtitle: filteredRequests.isEmpty ? "暂无匹配项" : "共 \(filteredRequests.count) 项",
            symbol: "doc.text.magnifyingglass"
        ) {
            if viewModel.isLoading && viewModel.requests.isEmpty {
                ProgressView("加载工单中...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 22)
            } else if filteredRequests.isEmpty {
                Text("当前筛选下暂无工单")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredRequests) { request in
                        ManagedRequestRow(
                            request: request,
                            baseURL: appState.environment.baseURL,
                            isSelected: viewModel.isSelected(request),
                            onToggleSelection: {
                                viewModel.toggleSelection(for: request)
                            },
                            isProcessing: viewModel.processingRequestID == request.id,
                            onAction: { action in
                                if action == .reject {
                                    rejectTarget = request
                                    rejectReason = ""
                                } else {
                                    Task {
                                        await viewModel.perform(
                                            action: action,
                                            request: request,
                                            rejectReason: nil,
                                            appState: appState
                                        )
                                    }
                                }
                            }
                        )
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

    private func sheetHero(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.indigo)
                .frame(width: 32, height: 32)
                .background(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                .clipShape(Circle())
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

    private func sheetCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.indigo)
                    .frame(width: 22, height: 22)
                    .background(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                    .clipShape(Circle())

                Text(title)
                    .font(.subheadline.weight(.semibold))
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

    private func performBatchAction(_ action: ManageRequestAction) async {
        await viewModel.performBatch(
            action: action,
            in: filteredRequests,
            rejectReason: nil,
            appState: appState
        )
    }

    private var cardSurface: Color {
        isDark ? Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.95) : Color.white.opacity(0.88)
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

private struct ManagedRequestRow: View {
    @EnvironmentObject private var appState: AppState

    let request: ManagedRequest
    let baseURL: String
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let isProcessing: Bool
    let onAction: (ManageRequestAction) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                    .font(.headline)
            }
            .buttonStyle(.plain)

            AsyncImage(url: posterURL(path: request.posterPath, baseURL: baseURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholder
                }
            }
            .frame(width: 54, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(request.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(metaLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let requestedBy = request.requestedBy, !requestedBy.isEmpty {
                    Text("申请人：\(requestedBy)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let created = request.createdAt, !created.isEmpty {
                    Text("创建：\(created.replacingOccurrences(of: "T", with: " ").prefix(16))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let rejectReason = request.rejectReason, !rejectReason.isEmpty {
                    Text("拒绝原因：\(rejectReason)")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                statusBadge

                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Menu {
                        ForEach(availableActions, id: \.rawValue) { action in
                            Button(action.title) {
                                onAction(action)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(rowSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.34) : Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private var metaLine: String {
        let typeText = request.mediaType == "tv" ? "剧集" : "电影"
        let seasonText = request.mediaType == "tv" ? " · S\(request.season)" : ""
        let yearText = request.year.isEmpty ? "" : " · \(request.year)"
        let countText = request.requestCount > 0 ? " · \(request.requestCount)人申请" : ""
        return "\(typeText)\(seasonText)\(yearText)\(countText)"
    }

    private var availableActions: [ManageRequestAction] {
        let status = ManagedRequestStatus(rawValue: request.status)
        switch status {
        case .pending:
            return [.approve, .manual, .reject, .delete]
        case .approved, .manual:
            return [.finish, .reject, .delete]
        case .rejected:
            return [.approve, .manual, .delete]
        case .done:
            return [.delete]
        }
    }

    private var statusBadge: some View {
        let status = ManagedRequestStatus(rawValue: request.status)
        return Text(status.title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.16))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: ManagedRequestStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .approved:
            return .blue
        case .done:
            return .green
        case .rejected:
            return .red
        case .manual:
            return .purple
        }
    }

    private var rowSurface: Color {
        appState.appearanceMode == .dark
            ? Color(red: 0.19, green: 0.21, blue: 0.25).opacity(0.95)
            : Color.white.opacity(0.78)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(rowSurface)
            Image(systemName: "film")
                .foregroundStyle(.secondary)
        }
    }

    private func posterURL(path: String?, baseURL: String) -> URL? {
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
}

private enum RequestFilter: String, CaseIterable, Identifiable {
    case pending
    case processing
    case done
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending:
            return "待处理"
        case .processing:
            return "处理中"
        case .done:
            return "已结束"
        case .all:
            return "全部"
        }
    }

    func matches(status: Int) -> Bool {
        switch self {
        case .pending:
            return status == ManagedRequestStatus.pending.rawValue
        case .processing:
            return status == ManagedRequestStatus.approved.rawValue || status == ManagedRequestStatus.manual.rawValue
        case .done:
            return status == ManagedRequestStatus.done.rawValue || status == ManagedRequestStatus.rejected.rawValue
        case .all:
            return true
        }
    }
}
