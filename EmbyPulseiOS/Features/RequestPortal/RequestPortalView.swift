import SwiftUI

struct RequestPortalView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = RequestPortalViewModel()
    @State private var mode: RequestPortalMode = .explore

    var body: some View {
        List {
            sessionSection

            Section {
                Picker("模块", selection: $mode) {
                    ForEach(RequestPortalMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            if let hint = viewModel.actionHint {
                Section {
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            switch mode {
            case .explore:
                exploreSections
            case .search:
                searchSections
            case .queue:
                queueSection
            case .feedback:
                feedbackSections
            }
        }
        .navigationTitle("用户侧求片")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refreshCurrentMode() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadInitial(appState: appState)
        }
        .refreshable {
            await refreshCurrentMode()
        }
        .onChange(of: mode) { mode in
            if mode == .queue {
                Task { await viewModel.loadMyRequests(appState: appState) }
            } else if mode == .feedback {
                Task { await viewModel.loadMyFeedbacks(appState: appState) }
            }
        }
        .sheet(item: $viewModel.activeMedia) { media in
            NavigationStack {
                RequestSubmitSheet(
                    media: media,
                    baseURL: appState.environment.baseURL,
                    viewModel: viewModel,
                    onSubmit: {
                        Task { _ = await viewModel.submitActiveRequest(appState: appState) }
                    }
                )
            }
        }
    }

    private var sessionSection: some View {
        Section("求片账号") {
            if let user = viewModel.portalUser {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                        Text("ID: \(user.id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("退出") {
                        Task { await viewModel.logout(appState: appState) }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                TextField("Emby 用户名", text: $viewModel.loginUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Emby 密码", text: $viewModel.loginPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    Task { _ = await viewModel.login(appState: appState) }
                } label: {
                    if viewModel.isAuthenticating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("登录求片系统")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isAuthenticating)
            }
        }
    }

    @ViewBuilder
    private var exploreSections: some View {
        Section("热门探索") {
            if viewModel.isLoadingTrending {
                ProgressView("加载热门内容...")
            } else {
                trendingBlock(title: "本周热门电影", items: viewModel.trending.movies)
                trendingBlock(title: "本周热门剧集", items: viewModel.trending.tv)
                trendingBlock(title: "高分电影榜", items: viewModel.trending.topMovies)
                trendingBlock(title: "高分剧集榜", items: viewModel.trending.topTV)
            }
        }
    }

    @ViewBuilder
    private func trendingBlock(title: String, items: [RequestMediaItem]) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                ForEach(Array(items.prefix(6))) { item in
                    RequestMediaRow(
                        media: item,
                        baseURL: appState.environment.baseURL,
                        onRequest: {
                            Task { await viewModel.openSubmitSheet(for: item, appState: appState) }
                        },
                        onFeedback: {
                            viewModel.prepareFeedback(itemName: item.title, posterPath: item.posterPath)
                            mode = .feedback
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var searchSections: some View {
        Section("搜索资源") {
            if !viewModel.isPortalLoggedIn {
                Text("搜索前请先登录求片账号")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                TextField("片名 / 关键词", text: $viewModel.searchQuery)
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
                .disabled(viewModel.isSearching || !viewModel.isPortalLoggedIn)
            }
        }

        Section("搜索结果") {
            if viewModel.isSearching {
                ProgressView("搜索中...")
            } else if viewModel.searchResults.isEmpty {
                Text("暂无结果")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.searchResults) { item in
                    RequestMediaRow(
                        media: item,
                        baseURL: appState.environment.baseURL,
                        onRequest: {
                            Task { await viewModel.openSubmitSheet(for: item, appState: appState) }
                        },
                        onFeedback: {
                            viewModel.prepareFeedback(itemName: item.title, posterPath: item.posterPath)
                            mode = .feedback
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var queueSection: some View {
        Section("我的求片记录") {
            if !viewModel.isPortalLoggedIn {
                Text("请先登录求片账号后查看")
                    .foregroundStyle(.secondary)
            } else if viewModel.isLoadingMyRequests {
                ProgressView("加载中...")
            } else if viewModel.myRequests.isEmpty {
                Text("暂无求片记录")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.myRequests) { item in
                    RequestQueueRow(
                        item: item,
                        baseURL: appState.environment.baseURL,
                        onFeedback: {
                            viewModel.prepareFeedback(itemName: item.title, posterPath: item.posterPath)
                            mode = .feedback
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var feedbackSections: some View {
        Section("提交报错") {
            if !viewModel.isPortalLoggedIn {
                Text("请先登录求片账号后提交报错")
                    .foregroundStyle(.secondary)
            }

            TextField("资源名称", text: $viewModel.feedbackItemName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Picker("问题类型", selection: $viewModel.feedbackIssueType) {
                ForEach(viewModel.feedbackIssueOptions, id: \.self) { issue in
                    Text(issue).tag(issue)
                }
            }
            .pickerStyle(.menu)

            TextField("问题描述（可选）", text: $viewModel.feedbackDescription, axis: .vertical)
                .lineLimit(2...5)

            Button {
                Task { _ = await viewModel.submitFeedback(appState: appState) }
            } label: {
                if viewModel.isSubmittingFeedback {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("提交报错")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSubmittingFeedback || !viewModel.isPortalLoggedIn)
        }

        Section("我的报错记录") {
            if !viewModel.isPortalLoggedIn {
                Text("请先登录求片账号后查看")
                    .foregroundStyle(.secondary)
            } else if viewModel.isLoadingMyFeedbacks {
                ProgressView("加载中...")
            } else if viewModel.myFeedbacks.isEmpty {
                Text("暂无报错记录")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.myFeedbacks) { item in
                    UserFeedbackRow(item: item)
                }
            }
        }
    }

    private func refreshCurrentMode() async {
        switch mode {
        case .explore:
            await viewModel.loadTrending(appState: appState)
        case .search:
            await viewModel.search(appState: appState)
        case .queue:
            await viewModel.loadMyRequests(appState: appState)
        case .feedback:
            await viewModel.loadMyFeedbacks(appState: appState)
        }
    }
}

private struct RequestMediaRow: View {
    let media: RequestMediaItem
    let baseURL: String
    let onRequest: () -> Void
    let onFeedback: () -> Void

    private var isMovieInLibrary: Bool {
        media.mediaType == "movie" && media.localStatus == 2
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: posterURL(path: media.posterPath, baseURL: baseURL)) { phase in
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
            .frame(width: 52, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(media.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Text(media.mediaType == "tv" ? "剧集" : "电影")
                    if !media.year.isEmpty {
                        Text(media.year)
                    }
                    if let vote = media.voteAverage {
                        Label(String(format: "%.1f", vote), systemImage: "star.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let overview = media.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Spacer()
                    Button("报错") {
                        onFeedback()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(isMovieInLibrary ? "已在库" : "求片") {
                        onRequest()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(isMovieInLibrary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct RequestQueueRow: View {
    let item: UserRequestItem
    let baseURL: String
    let onFeedback: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: posterURL(path: item.posterPath, baseURL: baseURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 48, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer()
                    statusBadge
                }

                HStack(spacing: 10) {
                    if !item.year.isEmpty {
                        Text(item.year)
                    }
                    if item.season > 0 {
                        Text("S\(item.season)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let requestedAt = item.requestedAt, !requestedAt.isEmpty {
                    Text(requestedAt.replacingOccurrences(of: "T", with: " ").prefix(16))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let rejectReason = item.rejectReason, !rejectReason.isEmpty {
                    Text("拒绝原因：\(rejectReason)")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }

                HStack {
                    Spacer()
                    Button("提交报错") {
                        onFeedback()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        let status = UserRequestStatus(rawValue: item.status)
        return Text(status.title)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: UserRequestStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .approved, .manual:
            return .blue
        case .done:
            return .green
        case .rejected:
            return .red
        }
    }
}

private struct UserFeedbackRow: View {
    let item: UserFeedbackItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.itemName)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()

                statusBadge
            }

            Text(item.issueType)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if let createdAt = item.createdAt, !createdAt.isEmpty {
                Text(createdAt.replacingOccurrences(of: "T", with: " ").prefix(16))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        let status = FeedbackStatus(rawValue: item.status)
        return Text(status.title)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: FeedbackStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .fixing:
            return .blue
        case .done:
            return .green
        case .ignored:
            return .gray
        }
    }
}

private struct RequestSubmitSheet: View {
    let media: RequestMediaItem
    let baseURL: String
    @ObservedObject var viewModel: RequestPortalViewModel
    let onSubmit: () -> Void

    private var isMovieInLibrary: Bool {
        media.mediaType == "movie" && media.localStatus == 2
    }

    var body: some View {
        Form {
            Section("资源信息") {
                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: posterURL(path: media.posterPath, baseURL: baseURL)) { phase in
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
                        Text(media.title)
                            .font(.headline)
                        HStack(spacing: 10) {
                            Text(media.mediaType == "tv" ? "剧集" : "电影")
                            if !media.year.isEmpty {
                                Text(media.year)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            if media.mediaType == "tv" {
                Section("季选择") {
                    if viewModel.isLoadingSeasons {
                        ProgressView("加载季信息...")
                    } else if viewModel.tvSeasons.isEmpty {
                        Text("暂无可选季")
                            .foregroundStyle(.secondary)
                    } else {
                        Button(viewModel.selectedSeasons.count == viewModel.availableTVSeasonNumbers.count ? "取消全选" : "全选可求季") {
                            viewModel.toggleSelectAllSeasons()
                        }
                        .buttonStyle(.bordered)

                        ForEach(viewModel.tvSeasons.sorted(by: { $0.seasonNumber < $1.seasonNumber })) { season in
                            let selected = viewModel.selectedSeasons.contains(season.seasonNumber)
                            Button {
                                viewModel.toggleSeason(season.seasonNumber)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("第 \(season.seasonNumber) 季 · \(season.name)")
                                        Text("\(season.episodeCount) 集")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if season.existsLocally {
                                        Text("已在库")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selected ? .blue : .secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(season.existsLocally)
                        }
                    }
                }
            }

            if isMovieInLibrary {
                Section {
                    Text("该电影已在库中，无需重复提交。")
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("提交求片")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    viewModel.dismissSubmitSheet()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    onSubmit()
                } label: {
                    if viewModel.isSubmittingRequest {
                        ProgressView()
                    } else {
                        Text("提交")
                    }
                }
                .disabled(
                    viewModel.isSubmittingRequest ||
                        viewModel.isLoadingSeasons ||
                        !viewModel.canSubmitActiveRequest
                )
            }
        }
    }
}

private enum RequestPortalMode: String, CaseIterable, Identifiable {
    case explore
    case search
    case queue
    case feedback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explore:
            return "探索"
        case .search:
            return "搜索"
        case .queue:
            return "我的"
        case .feedback:
            return "报错"
        }
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
