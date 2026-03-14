import Foundation

enum AdvancedStatsLoadGroup: String, CaseIterable, Hashable {
    case overviewBundle
    case topMovies
    case topUsers
    case recent
    case latest
    case libraries
}

@MainActor
final class AdvancedStatsViewModel: ObservableObject {
    @Published var users: [EmbyUserOption] = []
    @Published var selectedUserID: String = "all"
    @Published var topMoviesCategory: TopMoviesCategory = .all
    @Published var topMoviesSort: TopMoviesSort = .count
    @Published var topUsersPeriod: TopUsersPeriod = .week

    @Published var topMovies: [TopMovieItem] = []
    @Published var topUsers: [TopUserItem] = []
    @Published var badges: [StatBadge] = []
    @Published var userDetails: UserDetailData?
    @Published var monthlyPoints: [MonthlyDurationPoint] = []
    @Published var recentActivities: [RecentActivityItem] = []
    @Published var latestMedia: [LatestMediaItem] = []
    @Published var libraries: [LibraryViewItem] = []

    @Published var isLoading = false
    @Published var isRefreshingAll = false
    @Published var errorMessage: String?
    @Published var warningMessage: String?
    @Published var lastUpdatedAt: Date?
    @Published private(set) var loadingGroups: Set<AdvancedStatsLoadGroup> = []
    @Published private(set) var loadedGroups: Set<AdvancedStatsLoadGroup> = []

    private var groupErrors: [AdvancedStatsLoadGroup: String] = [:]
    private var groupRequestVersion: [AdvancedStatsLoadGroup: Int] = [:]

    var hourlyPoints: [HourlyPlayPoint] {
        let raw = userDetails?.hourly ?? [:]
        return (0..<24).map { hour in
            let key = String(format: "%02d", hour)
            return HourlyPlayPoint(hour: key, plays: raw[key] ?? 0)
        }
    }

    var libraryTypeSummaries: [LibraryTypeSummary] {
        let grouped = Dictionary(grouping: libraries) { item in
            let normalized = item.collectionType.trimmingCharacters(in: .whitespacesAndNewlines)
            return normalized.isEmpty ? "unknown" : normalized.lowercased()
        }

        return grouped.map { key, value in
            LibraryTypeSummary(type: key, count: value.count)
        }
        .sorted { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.type < rhs.type
            }
            return lhs.count > rhs.count
        }
    }

    var dominantActiveHour: HourlyPlayPoint? {
        hourlyPoints.max(by: { $0.plays < $1.plays })
    }

    func loadInitial(appState: AppState) async {
        isLoading = true
        errorMessage = nil
        warningMessage = nil

        await loadUsers(appState: appState)
        await reload(
            groups: defaultLoadOrder,
            appState: appState,
            force: false
        )

        await retryFailedGroupsIfNeeded(appState: appState)
        isLoading = false
    }

    func refresh(appState: AppState) async {
        await refreshAll(appState: appState)
    }

    func refreshAll(appState: AppState) async {
        isLoading = true
        isRefreshingAll = true
        errorMessage = nil
        warningMessage = nil

        await loadUsers(appState: appState, force: true)
        await reload(
            groups: defaultLoadOrder,
            appState: appState,
            force: true
        )
        await retryFailedGroupsIfNeeded(appState: appState)

        isRefreshingAll = false
        isLoading = false
    }

    func ensureGroupLoaded(
        _ group: AdvancedStatsLoadGroup,
        appState: AppState,
        force: Bool = false
    ) async {
        if !force, loadedGroups.contains(group) || loadingGroups.contains(group) {
            return
        }

        let requestID = beginRequest(for: group, force: force)
        let groupError: String?
        switch group {
        case .overviewBundle:
            groupError = await loadOverviewBundle(appState: appState, requestID: requestID)
        case .topMovies:
            groupError = await loadTopMovies(appState: appState, requestID: requestID)
        case .topUsers:
            groupError = await loadTopUsers(appState: appState, requestID: requestID)
        case .recent:
            groupError = await loadRecent(appState: appState, requestID: requestID)
        case .latest:
            groupError = await loadLatest(appState: appState, requestID: requestID)
        case .libraries:
            groupError = await loadLibraries(appState: appState, requestID: requestID)
        }

        guard !Task.isCancelled else {
            loadingGroups.remove(group)
            return
        }
        guard isCurrentRequest(requestID, for: group) else { return }
        loadingGroups.remove(group)
        loadedGroups.insert(group)
        groupErrors[group] = groupError
        lastUpdatedAt = Date()
        updateAggregateMessages()
    }

    func reload(
        groups: [AdvancedStatsLoadGroup],
        appState: AppState,
        force: Bool
    ) async {
        for group in groups {
            await ensureGroupLoaded(group, appState: appState, force: force)
        }
    }

    func invalidateForUserChange() {
        invalidate(groups: [.overviewBundle, .topMovies, .recent])
        badges = []
        userDetails = nil
        monthlyPoints = []
        topMovies = []
        recentActivities = []
    }

    func invalidateForTopMoviesFilterChange() {
        invalidate(groups: [.topMovies])
        topMovies = []
    }

    func invalidateForTopUsersPeriodChange() {
        invalidate(groups: [.topUsers])
        topUsers = []
    }

    func isLoading(_ group: AdvancedStatsLoadGroup) -> Bool {
        loadingGroups.contains(group)
    }

    func error(for group: AdvancedStatsLoadGroup) -> String? {
        groupErrors[group]
    }

    private func loadUsers(appState: AppState, force: Bool = false) async {
        if !force, !users.isEmpty {
            return
        }

        do {
            users = try await appState.apiClient.fetchUsers(baseURL: appState.environment.baseURL)
        } catch {
            guard !NetworkError.isCancellation(error) else { return }
            users = []
        }
    }

    private func beginRequest(for group: AdvancedStatsLoadGroup, force: Bool) -> Int {
        if force {
            loadedGroups.remove(group)
        }
        groupErrors[group] = nil
        loadingGroups.insert(group)
        let next = (groupRequestVersion[group] ?? 0) + 1
        groupRequestVersion[group] = next
        return next
    }

    private func isCurrentRequest(_ requestID: Int, for group: AdvancedStatsLoadGroup) -> Bool {
        groupRequestVersion[group] == requestID
    }

    private func invalidate(groups: [AdvancedStatsLoadGroup]) {
        for group in groups {
            groupRequestVersion[group] = (groupRequestVersion[group] ?? 0) + 1
            loadingGroups.remove(group)
            loadedGroups.remove(group)
            groupErrors[group] = nil
        }
        updateAggregateMessages()
    }

    private func loadOverviewBundle(appState: AppState, requestID: Int) async -> String? {
        var errors: [String] = []

        do {
            let result: [StatBadge] = try await requestWithRetry {
                try await appState.apiClient.fetchBadges(
                    baseURL: appState.environment.baseURL,
                    userID: selectedUserID
                )
            }
            guard isCurrentRequest(requestID, for: .overviewBundle) else { return nil }
            badges = result
        } catch {
            guard isCurrentRequest(requestID, for: .overviewBundle) else { return nil }
            guard !NetworkError.isCancellation(error) else { return nil }
            badges = []
            errors.append("勋章")
        }

        do {
            let result: UserDetailData = try await requestWithRetry {
                try await appState.apiClient.fetchUserDetails(
                    baseURL: appState.environment.baseURL,
                    userID: selectedUserID
                )
            }
            guard isCurrentRequest(requestID, for: .overviewBundle) else { return nil }
            userDetails = result
        } catch {
            guard isCurrentRequest(requestID, for: .overviewBundle) else { return nil }
            guard !NetworkError.isCancellation(error) else { return nil }
            userDetails = nil
            errors.append("用户画像")
        }

        do {
            let result: [MonthlyDurationPoint] = try await requestWithRetry {
                try await appState.apiClient.fetchMonthlyStats(
                    baseURL: appState.environment.baseURL,
                    userID: selectedUserID
                )
            }
            guard isCurrentRequest(requestID, for: .overviewBundle) else { return nil }
            monthlyPoints = result
        } catch {
            guard isCurrentRequest(requestID, for: .overviewBundle) else { return nil }
            guard !NetworkError.isCancellation(error) else { return nil }
            monthlyPoints = []
            errors.append("月度趋势")
        }

        if errors.isEmpty {
            return nil
        }
        return "以下数据加载失败：\(errors.joined(separator: "、"))"
    }

    private func loadTopMovies(appState: AppState, requestID: Int) async -> String? {
        do {
            let result = try await appState.apiClient.fetchTopMovies(
                baseURL: appState.environment.baseURL,
                userID: selectedUserID,
                category: topMoviesCategory,
                sortBy: topMoviesSort
            )
            guard isCurrentRequest(requestID, for: .topMovies) else { return nil }
            topMovies = result
            return nil
        } catch {
            guard isCurrentRequest(requestID, for: .topMovies) else { return nil }
            guard !NetworkError.isCancellation(error) else { return nil }
            topMovies = []
            return error.localizedDescription
        }
    }

    private func loadTopUsers(appState: AppState, requestID: Int) async -> String? {
        do {
            let result = try await appState.apiClient.fetchTopUsers(
                baseURL: appState.environment.baseURL,
                period: topUsersPeriod
            )
            guard isCurrentRequest(requestID, for: .topUsers) else { return nil }
            topUsers = result
            return nil
        } catch {
            guard isCurrentRequest(requestID, for: .topUsers) else { return nil }
            guard !NetworkError.isCancellation(error) else { return nil }
            topUsers = []
            return error.localizedDescription
        }
    }

    private func loadRecent(appState: AppState, requestID: Int) async -> String? {
        do {
            let result = try await appState.apiClient.fetchRecentActivities(
                baseURL: appState.environment.baseURL,
                userID: selectedUserID
            )
            guard isCurrentRequest(requestID, for: .recent) else { return nil }
            recentActivities = result
            return nil
        } catch {
            guard isCurrentRequest(requestID, for: .recent) else { return nil }
            guard !NetworkError.isCancellation(error) else { return nil }
            recentActivities = []
            return error.localizedDescription
        }
    }

    private func loadLatest(appState: AppState, requestID: Int) async -> String? {
        do {
            let result = try await appState.apiClient.fetchLatestMedia(
                baseURL: appState.environment.baseURL,
                limit: 12
            )
            guard isCurrentRequest(requestID, for: .latest) else { return nil }
            latestMedia = result
            return nil
        } catch {
            guard isCurrentRequest(requestID, for: .latest) else { return nil }
            guard !NetworkError.isCancellation(error) else { return nil }
            latestMedia = []
            return error.localizedDescription
        }
    }

    private func loadLibraries(appState: AppState, requestID: Int) async -> String? {
        do {
            let result = try await appState.apiClient.fetchLibraries(
                baseURL: appState.environment.baseURL
            )
            guard isCurrentRequest(requestID, for: .libraries) else { return nil }
            libraries = result
            return nil
        } catch {
            guard isCurrentRequest(requestID, for: .libraries) else { return nil }
            guard !NetworkError.isCancellation(error) else { return nil }
            libraries = []
            return error.localizedDescription
        }
    }

    private func updateAggregateMessages() {
        let nonEmptyErrors = groupErrors.values.filter { !$0.isEmpty }
        errorMessage = nonEmptyErrors.first
        if nonEmptyErrors.count > 1 {
            warningMessage = "部分区块加载失败（\(nonEmptyErrors.count)项），可下拉重试"
        } else {
            warningMessage = nil
        }
    }

    private var defaultLoadOrder: [AdvancedStatsLoadGroup] {
        [.overviewBundle, .topMovies, .topUsers, .recent, .latest, .libraries]
    }

    private func retryFailedGroupsIfNeeded(appState: AppState) async {
        let failedGroups = defaultLoadOrder.filter { !(groupErrors[$0] ?? "").isEmpty }
        guard !failedGroups.isEmpty else { return }

        warningMessage = "网络波动，正在重试加载失败区块..."
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard !Task.isCancelled else { return }
        await reload(groups: failedGroups, appState: appState, force: true)
    }

    private func requestWithRetry<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            if NetworkError.isCancellation(error) {
                throw error
            }
            guard shouldRetry(error) else {
                throw error
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            try Task.checkCancellation()
            return try await operation()
        }
    }

    private func shouldRetry(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else {
            return false
        }

        switch networkError {
        case .transport, .invalidResponse:
            return true
        case .invalidBaseURL, .unauthorized, .server:
            return false
        }
    }
}

struct HourlyPlayPoint: Identifiable {
    let hour: String
    let plays: Int

    var id: String { hour }
}

struct LibraryTypeSummary: Identifiable {
    let type: String
    let count: Int

    var id: String { type }

    var displayName: String {
        switch type {
        case "movies", "movie":
            return "电影"
        case "tvshows", "tvshow", "series":
            return "剧集"
        case "music":
            return "音乐"
        case "books":
            return "图书"
        case "unknown":
            return "未知类型"
        default:
            return type.uppercased()
        }
    }
}
