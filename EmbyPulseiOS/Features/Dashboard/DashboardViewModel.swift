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
        isLoading = true
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

        var errors: [String] = []

        do {
            dashboard = try await dashboardTask
        } catch {
            dashboard = nil
            errors.append("仪表盘指标")
        }

        do {
            liveSessions = try await liveTask
        } catch {
            liveSessions = []
            errors.append("实时会话")
        }

        do {
            latestMedia = try await latestTask
        } catch {
            latestMedia = []
            errors.append("最近入库")
        }

        do {
            recentActivities = try await recentTask
        } catch {
            recentActivities = []
            errors.append("最近播放")
        }

        do {
            trendPoints = try await trendTask
        } catch {
            trendPoints = []
            errors.append("趋势追踪")
        }

        do {
            libraries = try await librariesTask
        } catch {
            libraries = []
            errors.append("我的媒体库")
        }

        do {
            platinumUsers = try await rankingTask
        } catch {
            platinumUsers = []
            errors.append("白金观影榜")
        }

        if let first = errors.first {
            errorMessage = "加载失败：\(first)"
        }
        if errors.count > 1 {
            warningMessage = "部分模块加载失败（\(errors.count)项）"
        }
        lastUpdatedAt = Date()

        isLoading = false
    }

    func refreshPlatinumRanking(appState: AppState) async {
        do {
            platinumUsers = try await appState.apiClient.fetchTopUsers(
                baseURL: appState.environment.baseURL,
                period: platinumPeriod
            )
        } catch {
            platinumUsers = []
            errorMessage = error.localizedDescription
        }
    }
}
