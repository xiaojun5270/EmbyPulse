import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var dashboard: DashboardData?
    @Published var liveSessions: [LiveSession] = []
    @Published var latestMedia: [LatestMediaItem] = []
    @Published var recentActivities: [RecentActivityItem] = []
    @Published var trendPoints: [TrendPoint] = []
    @Published var libraries: [LibraryViewItem] = []
    @Published var platinumUsers: [TopUserItem] = []
    @Published var platinumPeriod: TopUsersPeriod = .week
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var warningMessage: String?
    @Published var lastUpdatedAt: Date?

    func refresh(appState: AppState) async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        errorMessage = nil
        warningMessage = nil

        async let dashboardTask = appState.apiClient.fetchDashboard(baseURL: appState.environment.baseURL)
        async let liveTask = appState.apiClient.fetchLiveSessions(baseURL: appState.environment.baseURL)
        async let latestTask = appState.apiClient.fetchLatestMedia(baseURL: appState.environment.baseURL, limit: 12)
        async let recentTask = appState.apiClient.fetchRecentActivities(baseURL: appState.environment.baseURL, userID: "all")
        async let trendTask = appState.apiClient.fetchTrendData(
            baseURL: appState.environment.baseURL,
            userID: "all",
            dimension: .day
        )
        async let librariesTask = appState.apiClient.fetchLibraries(baseURL: appState.environment.baseURL)
        async let rankingTask = appState.apiClient.fetchTopUsers(
            baseURL: appState.environment.baseURL,
            period: platinumPeriod
        )

        var criticalFailures: [String] = []
        var supplementaryFailureCount = 0

        do {
            dashboard = try await dashboardTask
        } catch {
            if NetworkError.isCancellation(error) {
                return
            }
            criticalFailures.append("核心概览")
        }

        do {
            liveSessions = try await liveTask
        } catch {
            if NetworkError.isCancellation(error) {
                return
            }
            criticalFailures.append("实时会话")
        }

        do {
            latestMedia = try await latestTask
        } catch {
            if NetworkError.isCancellation(error) {
                return
            }
            supplementaryFailureCount += 1
        }

        do {
            recentActivities = try await recentTask
        } catch {
            if NetworkError.isCancellation(error) {
                return
            }
            supplementaryFailureCount += 1
        }

        do {
            trendPoints = try await trendTask
        } catch {
            if NetworkError.isCancellation(error) {
                return
            }
            supplementaryFailureCount += 1
        }

        do {
            libraries = try await librariesTask
        } catch {
            if NetworkError.isCancellation(error) {
                return
            }
            supplementaryFailureCount += 1
        }

        do {
            platinumUsers = try await rankingTask
        } catch {
            if NetworkError.isCancellation(error) {
                return
            }
            supplementaryFailureCount += 1
        }

        if let first = criticalFailures.first {
            errorMessage = "加载失败：\(first)"
        } else if lastUpdatedAt == nil, supplementaryFailureCount > 0 {
            warningMessage = "部分扩展模块首次加载失败"
        }

        lastUpdatedAt = Date()
    }

    func refreshPlatinumRanking(appState: AppState) async {
        do {
            platinumUsers = try await appState.apiClient.fetchTopUsers(
                baseURL: appState.environment.baseURL,
                period: platinumPeriod
            )
        } catch {
            guard !NetworkError.isCancellation(error) else { return }
            errorMessage = error.localizedDescription
        }
    }
}
