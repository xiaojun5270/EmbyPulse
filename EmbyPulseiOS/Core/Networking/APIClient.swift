import Foundation

final class APIClient {
    static let shared = APIClient()

    private static let requestTimeout: TimeInterval = 60
    private static let resourceTimeout: TimeInterval = 180
    private static let maxRetryCount = 1

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = .shared
        config.httpShouldSetCookies = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = Self.requestTimeout
        config.timeoutIntervalForResource = Self.resourceTimeout
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func login(baseURL: String, username: String, password: String) async throws {
        let requestBody = LoginRequest(username: username, password: password)
        let response: APIStatusResponse = try await send(
            path: "/api/login",
            baseURL: baseURL,
            method: "POST",
            body: requestBody
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "登录失败")
        }
    }

    func registerWithInvite(
        baseURL: String,
        code: String,
        username: String,
        password: String
    ) async throws -> InviteRegisterResponse {
        let payload = InviteRegisterPayload(code: code, username: username, password: password)
        let response: InviteRegisterResponse = try await send(
            path: "/api/register",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "注册失败")
        }
        return response
    }

    func fetchDashboard(baseURL: String, userID: String? = nil) async throws -> DashboardData {
        var queryItems: [URLQueryItem] = []
        if let userID, !userID.isEmpty {
            queryItems.append(URLQueryItem(name: "user_id", value: userID))
        }

        let response: APIWrappedResponse<DashboardData> = try await send(
            path: "/api/stats/dashboard",
            baseURL: baseURL,
            queryItems: queryItems
        )

        guard response.isSuccess, let data = response.data else {
            throw NetworkError.server(message: response.message ?? "获取 Dashboard 失败")
        }
        return data
    }

    func fetchLiveSessions(baseURL: String) async throws -> [LiveSession] {
        let response: APIWrappedResponse<[LiveSession]> = try await send(
            path: "/api/stats/live",
            baseURL: baseURL
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取实时播放失败")
        }
        return response.data ?? []
    }

    func fetchCalendarWeekly(
        baseURL: String,
        offset: Int = 0,
        refresh: Bool = false
    ) async throws -> CalendarWeeklyResponse {
        return try await send(
            path: "/api/calendar/weekly",
            baseURL: baseURL,
            queryItems: [
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "refresh", value: refresh ? "true" : "false")
            ]
        )
    }

    func updateCalendarConfig(baseURL: String, ttl: Int) async throws {
        let payload = CalendarTTLConfigPayload(ttl: ttl)
        let response: APIStatusResponse = try await send(
            path: "/api/calendar/config",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "更新日历缓存失败")
        }
    }

    func fetchManagedRequests(baseURL: String) async throws -> [ManagedRequest] {
        let response: APIWrappedResponse<[ManagedRequest]> = try await send(
            path: "/api/manage/requests",
            baseURL: baseURL
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取工单失败")
        }
        return response.data ?? []
    }

    func performManagedRequestAction(
        baseURL: String,
        tmdbID: Int,
        season: Int,
        action: ManageRequestAction,
        rejectReason: String? = nil
    ) async throws {
        let payload = ManagedRequestActionPayload(
            tmdbID: tmdbID,
            season: season,
            action: action.rawValue,
            rejectReason: rejectReason
        )

        let response: APIStatusResponse = try await send(
            path: "/api/manage/requests/action",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "执行工单操作失败")
        }
    }

    func performManagedRequestsBatch(
        baseURL: String,
        items: [ManagedRequestBatchItem],
        action: ManageRequestAction,
        rejectReason: String? = nil
    ) async throws {
        let payload = ManagedRequestBatchPayload(
            items: items.map { ManagedRequestBatchPayloadItem(tmdbID: $0.tmdbID, season: $0.season) },
            action: action.rawValue,
            rejectReason: rejectReason
        )

        let response: APIStatusResponse = try await send(
            path: "/api/manage/requests/batch",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "批量工单操作失败")
        }
    }

    func fetchTopMovies(
        baseURL: String,
        userID: String,
        category: TopMoviesCategory,
        sortBy: TopMoviesSort,
        period: TopMoviesPeriod = .all
    ) async throws -> [TopMovieItem] {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "category", value: category.rawValue),
            URLQueryItem(name: "period", value: period.rawValue),
            URLQueryItem(name: "sort_by", value: sortBy.rawValue)
        ]

        let response: TopMoviesResponse = try await send(
            path: "/api/stats/top_movies",
            baseURL: baseURL,
            queryItems: queryItems
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取热门内容失败")
        }
        return response.data ?? []
    }

    func fetchTopUsers(baseURL: String, period: TopUsersPeriod) async throws -> [TopUserItem] {
        let response: TopUsersListResponse = try await send(
            path: "/api/stats/top_users_list",
            baseURL: baseURL,
            queryItems: [URLQueryItem(name: "period", value: period.rawValue)]
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取活跃用户失败")
        }
        return response.data ?? []
    }

    func fetchBadges(baseURL: String, userID: String) async throws -> [StatBadge] {
        let response: BadgesResponse = try await send(
            path: "/api/stats/badges",
            baseURL: baseURL,
            queryItems: [URLQueryItem(name: "user_id", value: userID)]
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: "获取勋章数据失败")
        }
        return response.data ?? []
    }

    func fetchUserDetails(baseURL: String, userID: String) async throws -> UserDetailData {
        let response: UserDetailsResponse = try await send(
            path: "/api/stats/user_details",
            baseURL: baseURL,
            queryItems: [URLQueryItem(name: "user_id", value: userID)]
        )
        guard response.isSuccess, let data = response.data else {
            throw NetworkError.server(message: response.message ?? "获取用户画像失败")
        }
        return data
    }

    func fetchMonthlyStats(baseURL: String, userID: String) async throws -> [MonthlyDurationPoint] {
        let response: MonthlyStatsResponse = try await send(
            path: "/api/stats/monthly_stats",
            baseURL: baseURL,
            queryItems: [URLQueryItem(name: "user_id", value: userID)]
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取月度趋势失败")
        }

        let points = (response.data ?? [:]).map {
            MonthlyDurationPoint(month: $0.key, durationSeconds: $0.value)
        }
        return points.sorted { $0.month < $1.month }
    }

    func fetchRecentActivities(baseURL: String, userID: String) async throws -> [RecentActivityItem] {
        var queryItems: [URLQueryItem] = []
        if userID != "all" {
            queryItems.append(URLQueryItem(name: "user_id", value: userID))
        }

        let response: RecentActivityResponse = try await send(
            path: "/api/stats/recent",
            baseURL: baseURL,
            queryItems: queryItems
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取最近动态失败")
        }
        return response.data ?? []
    }

    func fetchLatestMedia(baseURL: String, limit: Int = 10) async throws -> [LatestMediaItem] {
        let response: LatestMediaResponse = try await send(
            path: "/api/stats/latest",
            baseURL: baseURL,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取最新入库失败")
        }
        return response.data ?? []
    }

    func fetchLibraries(baseURL: String) async throws -> [LibraryViewItem] {
        let response: LibrariesResponse = try await send(
            path: "/api/stats/libraries",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取媒体库失败")
        }
        return response.data ?? []
    }

    func fetchUsers(baseURL: String) async throws -> [EmbyUserOption] {
        let response: APIWrappedResponse<[EmbyUserOption]> = try await send(
            path: "/api/users",
            baseURL: baseURL
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取用户列表失败")
        }
        return response.data ?? []
    }

    func fetchHistoryList(
        baseURL: String,
        page: Int,
        limit: Int,
        userID: String,
        keyword: String
    ) async throws -> PlaybackHistoryListResponse {
        let response: PlaybackHistoryListResponse = try await send(
            path: "/api/history/list",
            baseURL: baseURL,
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "keyword", value: keyword)
            ]
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取播放历史失败")
        }
        return response
    }

    func fetchTrendData(
        baseURL: String,
        userID: String,
        dimension: TrendDimension
    ) async throws -> [TrendPoint] {
        let response: APIWrappedResponse<[String: Int]> = try await send(
            path: "/api/stats/trend",
            baseURL: baseURL,
            queryItems: [
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "dimension", value: dimension.rawValue)
            ]
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取趋势数据失败")
        }

        let mapped = (response.data ?? [:]).map { key, value in
            TrendPoint(label: key, durationSeconds: value)
        }
        return mapped.sorted { $0.label < $1.label }
    }

    func fetchClientBlacklist(baseURL: String) async throws -> [ClientBlacklistItem] {
        let response: APIWrappedResponse<[ClientBlacklistItem]> = try await send(
            path: "/api/clients/blacklist",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取客户端黑名单失败")
        }
        return response.data ?? []
    }

    func addClientBlacklist(baseURL: String, appName: String) async throws {
        let payload = ClientBlacklistPayload(appName: appName)
        let response: APIStatusResponse = try await send(
            path: "/api/clients/blacklist",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "添加黑名单失败")
        }
    }

    func deleteClientBlacklist(baseURL: String, appName: String) async throws {
        let encodedName = appName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? appName
        let response: APIStatusResponse = try await send(
            path: "/api/clients/blacklist/\(encodedName)",
            baseURL: baseURL,
            method: "DELETE"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "删除黑名单失败")
        }
    }

    func fetchClientsData(baseURL: String) async throws -> ClientDataResponse {
        let response: ClientDataResponse = try await send(
            path: "/api/clients/data",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取客户端数据失败")
        }
        return response
    }

    func executeClientsBlock(baseURL: String) async throws -> String {
        let response: APIStatusResponse = try await send(
            path: "/api/clients/execute_block",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "执行客户端阻断失败")
        }
        return response.message ?? "执行完成"
    }

    func searchLibrary(baseURL: String, query: String) async throws -> [LibrarySearchItem] {
        let response: APIWrappedResponse<[LibrarySearchItem]> = try await send(
            path: "/api/library/search",
            baseURL: baseURL,
            queryItems: [URLQueryItem(name: "query", value: query)]
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "媒体库搜索失败")
        }
        return response.data ?? []
    }

    func fetchInsightQuality(baseURL: String, forceRefresh: Bool) async throws -> InsightQualityStats {
        let response: InsightQualityResponse = try await send(
            path: "/api/insight/quality",
            baseURL: baseURL,
            queryItems: forceRefresh ? [URLQueryItem(name: "force_refresh", value: "true")] : []
        )
        guard response.isSuccess, let data = response.data else {
            throw NetworkError.server(message: response.message ?? "获取质量盘点失败")
        }
        return data
    }

    func fetchInsightIgnores(baseURL: String) async throws -> [InsightIgnoreItem] {
        let response: APIWrappedResponse<[InsightIgnoreItem]> = try await send(
            path: "/api/insight/ignores",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取回收站失败")
        }
        return response.data ?? []
    }

    func ignoreInsightItems(baseURL: String, items: [(itemID: String, itemName: String)]) async throws {
        let payload = InsightIgnoreBatchPayload(items: items.map {
            InsightIgnorePayloadItem(itemID: $0.itemID, itemName: $0.itemName)
        })
        let response: APIStatusResponse = try await send(
            path: "/api/insight/ignore_batch",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "批量忽略失败")
        }
    }

    func unignoreInsightItems(baseURL: String, itemIDs: [String]) async throws {
        let payload = InsightUnignoreBatchPayload(itemIDs: itemIDs)
        let response: APIStatusResponse = try await send(
            path: "/api/insight/unignore_batch",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "恢复忽略项失败")
        }
    }

    func fetchGapScanProgress(baseURL: String) async throws -> GapScanState {
        let response: GapScanProgressResponse = try await send(
            path: "/api/gaps/scan/progress",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取缺集扫描进度失败")
        }
        return response.data ?? GapScanState()
    }

    func startGapScan(baseURL: String) async throws {
        let response: APIStatusResponse = try await send(
            path: "/api/gaps/scan/start",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "启动缺集扫描失败")
        }
    }

    func fetchGapAutoScanEnabled(baseURL: String) async throws -> Bool {
        let response: GapAutoStatusResponse = try await send(
            path: "/api/gaps/scan/auto_status",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取自动巡检状态失败")
        }
        return response.enabled
    }

    func setGapAutoScan(baseURL: String, enabled: Bool) async throws {
        let payload = GapAutoTogglePayload(enabled: enabled)
        let response: APIStatusResponse = try await send(
            path: "/api/gaps/scan/auto_toggle",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "更新自动巡检失败")
        }
    }

    func ignoreGapEpisode(
        baseURL: String,
        seriesID: String,
        seriesName: String,
        season: Int,
        episode: Int
    ) async throws {
        let payload = GapIgnoreEpisodePayload(
            seriesID: seriesID,
            seriesName: seriesName,
            seasonNumber: season,
            episodeNumber: episode
        )
        let response: APIStatusResponse = try await send(
            path: "/api/gaps/ignore",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "忽略缺集失败")
        }
    }

    func ignoreGapSeries(
        baseURL: String,
        seriesID: String,
        seriesName: String
    ) async throws {
        let payload = GapIgnoreSeriesPayload(seriesID: seriesID, seriesName: seriesName)
        let response: APIStatusResponse = try await send(
            path: "/api/gaps/ignore/series",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "忽略整剧失败")
        }
    }

    func fetchGapIgnores(baseURL: String) async throws -> [GapIgnoredItem] {
        let response: GapIgnoresResponse = try await send(
            path: "/api/gaps/ignores",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取缺集回收站失败")
        }
        return response.data ?? []
    }

    func unignoreGap(baseURL: String, item: GapIgnoredItem) async throws {
        let payload = GapUnignorePayload(type: item.type, id: item.rawID)
        let response: APIStatusResponse = try await send(
            path: "/api/gaps/unignore",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "恢复缺集条目失败")
        }
    }

    func fetchGapConfig(baseURL: String) async throws -> GapClientConfig {
        let response: GapConfigResponse = try await send(
            path: "/api/gaps/config",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取缺集下载器配置失败")
        }
        return GapClientConfig(map: response.data ?? [:])
    }

    func saveGapConfig(baseURL: String, config: GapClientConfig) async throws {
        let payload = GapConfigSavePayload(
            clientType: config.clientType,
            clientURL: config.clientURL,
            clientUser: config.clientUser,
            clientPass: config.clientPass
        )
        let response: APIStatusResponse = try await send(
            path: "/api/gaps/config",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "保存缺集下载器配置失败")
        }
    }

    func searchGapResources(
        baseURL: String,
        seriesID: String,
        seriesName: String,
        season: Int,
        episodes: [Int],
        customKeyword: String? = nil
    ) async throws -> GapMPSearchData {
        let keyword = customKeyword?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let searchName: String
        if let keyword, !keyword.isEmpty {
            searchName = keyword
        } else {
            searchName = seriesName
        }

        let payload = GapSearchMPPayload(
            seriesID: seriesID,
            seriesName: searchName,
            season: season,
            episodes: episodes
        )
        let response: GapMPSearchResponse = try await send(
            path: "/api/gaps/search_mp",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess, let data = response.data else {
            throw NetworkError.server(message: response.message ?? "缺集配型搜索失败")
        }
        return data
    }

    func submitGapDownload(
        baseURL: String,
        seriesID: String,
        seriesName: String,
        tmdbID: String?,
        season: Int,
        episodes: [Int],
        torrent: GapMPTorrentResult
    ) async throws -> String {
        let payload = GapDownloadPayload(
            seriesID: seriesID,
            seriesName: seriesName,
            tmdbID: tmdbID,
            season: season,
            episodes: episodes,
            torrentInfo: torrent.raw
        )
        let response: APIStatusResponse = try await send(
            path: "/api/gaps/download",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "下发缺集下载任务失败")
        }
        return response.message ?? "已提交下载任务"
    }

    func fetchBotSettings(baseURL: String) async throws -> BotSettingsData {
        let response: BotSettingsResponse = try await send(
            path: "/api/bot/settings",
            baseURL: baseURL
        )
        guard response.isSuccess, let data = response.data else {
            throw NetworkError.server(message: response.message ?? "获取 Bot 配置失败")
        }
        return data
    }

    func saveBotSettings(baseURL: String, draft: BotSettingsDraft) async throws {
        let payload = BotSettingsSavePayload(
            tgBotToken: draft.tgBotToken,
            tgChatID: draft.tgChatID,
            enableBot: draft.enableBot,
            enableNotify: draft.enableNotify,
            enableLibraryNotify: draft.enableLibraryNotify,
            wecomCorpid: draft.wecomCorpid,
            wecomCorpsecret: draft.wecomCorpsecret,
            wecomAgentid: draft.wecomAgentid,
            wecomTouser: draft.wecomTouser,
            wecomProxyURL: draft.wecomProxyURL,
            wecomToken: draft.wecomToken,
            wecomAESKey: draft.wecomAESKey
        )
        let response: APIStatusResponse = try await send(
            path: "/api/bot/settings",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "保存 Bot 配置失败")
        }
    }

    func testBotConnection(baseURL: String) async throws {
        let response: APIStatusResponse = try await send(
            path: "/api/bot/test",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "Telegram 测试失败")
        }
    }

    func testWeComConnection(baseURL: String) async throws {
        let response: APIStatusResponse = try await send(
            path: "/api/bot/test_wecom",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "企业微信测试失败")
        }
    }

    func fetchSystemSettings(baseURL: String) async throws -> SystemSettingsData {
        let response: SystemSettingsResponse = try await send(
            path: "/api/settings",
            baseURL: baseURL
        )
        guard response.isSuccess, let data = response.data else {
            throw NetworkError.server(message: response.message ?? "获取系统设置失败")
        }
        return data
    }

    func saveSystemSettings(baseURL: String, draft: SystemSettingsDraft) async throws {
        let payload = SystemSettingsSavePayload(
            embyHost: draft.embyHost,
            embyAPIKey: draft.embyAPIKey,
            tmdbAPIKey: draft.tmdbAPIKey,
            proxyURL: draft.proxyURL,
            webhookToken: draft.webhookToken,
            hiddenUsers: draft.hiddenUsers,
            embyPublicURL: draft.embyPublicURL,
            welcomeMessage: draft.welcomeMessage,
            clientDownloadURL: draft.clientDownloadURL,
            moviepilotURL: draft.moviepilotURL,
            moviepilotToken: draft.moviepilotToken,
            pulseURL: draft.pulseURL
        )
        let response: APIStatusResponse = try await send(
            path: "/api/settings",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "保存系统设置失败")
        }
    }

    func testTMDBConnection(baseURL: String) async throws -> String {
        let response: APIStatusResponse = try await send(
            path: "/api/settings/test_tmdb",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "TMDB 连通测试失败")
        }
        return response.message ?? "TMDB 连接成功"
    }

    func testMoviePilotConnection(baseURL: String, mpURL: String, mpToken: String) async throws -> String {
        let payload = MoviePilotTestPayload(mpURL: mpURL, mpToken: mpToken)
        let response: APIStatusResponse = try await send(
            path: "/api/settings/test_mp",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "MoviePilot 连通测试失败")
        }
        return response.message ?? "MoviePilot 测试成功"
    }

    func fixDatabase(baseURL: String) async throws -> String {
        let response: APIStatusResponse = try await send(
            path: "/api/settings/fix_db",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "数据库修复失败")
        }
        return response.message ?? "数据库结构检查完成"
    }

    func fetchTasks(baseURL: String) async throws -> [TaskGroup] {
        let response: TaskGroupsResponse = try await send(
            path: "/api/tasks",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取任务列表失败")
        }
        return response.data ?? []
    }

    func translateTask(baseURL: String, originalName: String, translatedName: String) async throws {
        let payload = TaskTranslatePayload(
            originalName: originalName,
            translatedName: translatedName
        )
        let response: APIStatusResponse = try await send(
            path: "/api/tasks/translate",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "任务别名保存失败")
        }
    }

    func startTask(baseURL: String, taskID: String) async throws {
        let response: APIStatusResponse = try await send(
            path: "/api/tasks/\(taskID)/start",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "任务启动失败")
        }
    }

    func stopTask(baseURL: String, taskID: String) async throws {
        let response: APIStatusResponse = try await send(
            path: "/api/tasks/\(taskID)/stop",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "任务停止失败")
        }
    }

    func fetchPosterData(baseURL: String, userID: String, period: ReportPeriod) async throws -> PosterData {
        let response: PosterDataResponse = try await send(
            path: "/api/stats/poster_data",
            baseURL: baseURL,
            queryItems: [
                URLQueryItem(name: "user_id", value: userID),
                URLQueryItem(name: "period", value: period.rawValue)
            ]
        )
        guard response.isSuccess, let data = response.data else {
            throw NetworkError.server(message: response.message ?? "获取报表数据失败")
        }
        return data
    }

    func pushReport(
        baseURL: String,
        userID: String,
        period: ReportPeriod,
        theme: ReportTheme
    ) async throws {
        let payload = ReportPushPayload(
            userID: userID,
            period: period.rawValue,
            theme: theme.rawValue
        )
        let response: APIStatusResponse = try await send(
            path: "/api/report/push",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "报表推送失败")
        }
    }

    func requestPortalLogin(baseURL: String, username: String, password: String) async throws -> RequestPortalUser {
        let payload = RequestPortalLoginPayload(username: username, password: password)
        let response: APIStatusResponse = try await send(
            path: "/api/requests/auth",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "求片系统登录失败")
        }

        let session = try await fetchRequestPortalSession(baseURL: baseURL)
        guard session.isSuccess, let user = session.user else {
            throw NetworkError.server(message: "求片系统会话获取失败")
        }
        return user
    }

    func fetchRequestPortalSession(baseURL: String) async throws -> RequestPortalSessionResponse {
        return try await send(
            path: "/api/requests/check",
            baseURL: baseURL
        )
    }

    func requestPortalLogout(baseURL: String) async throws {
        let response: APIStatusResponse = try await send(
            path: "/api/requests/logout",
            baseURL: baseURL,
            method: "POST"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "退出求片系统失败")
        }
    }

    func fetchRequestTrending(baseURL: String) async throws -> RequestTrendingGroups {
        let response: APIWrappedResponse<RequestTrendingGroups> = try await send(
            path: "/api/requests/trending",
            baseURL: baseURL
        )
        guard response.isSuccess, let data = response.data else {
            throw NetworkError.server(message: response.message ?? "获取热门失败")
        }
        return data
    }

    func searchRequestMedia(baseURL: String, query: String) async throws -> [RequestMediaItem] {
        let response: APIWrappedResponse<[RequestMediaItem]> = try await send(
            path: "/api/requests/search",
            baseURL: baseURL,
            queryItems: [URLQueryItem(name: "query", value: query)]
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "搜索失败")
        }
        return response.data ?? []
    }

    func fetchTVSeasons(baseURL: String, tmdbID: Int) async throws -> [TVSeasonInfo] {
        let response: TVSeasonResponse = try await send(
            path: "/api/requests/tv/\(tmdbID)",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取季信息失败")
        }
        return response.seasons
    }

    func submitUserRequest(
        baseURL: String,
        media: RequestMediaItem,
        seasons: [Int]
    ) async throws {
        let payload = RequestSubmitPayload(
            tmdbID: media.tmdbID,
            mediaType: media.mediaType,
            title: media.title,
            year: media.year,
            posterPath: media.posterPath ?? "",
            overview: media.overview ?? "",
            seasons: seasons.isEmpty ? [0] : seasons
        )
        let response: APIStatusResponse = try await send(
            path: "/api/requests/submit",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "提交求片失败")
        }
    }

    func fetchMyUserRequests(baseURL: String) async throws -> [UserRequestItem] {
        let response: APIWrappedResponse<[UserRequestItem]> = try await send(
            path: "/api/requests/my",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取我的求片失败")
        }
        return response.data ?? []
    }

    func submitRequestFeedback(
        baseURL: String,
        itemName: String,
        issueType: String,
        description: String,
        posterPath: String?
    ) async throws {
        let payload = RequestFeedbackSubmitPayload(
            itemName: itemName,
            issueType: issueType,
            description: description,
            posterPath: posterPath ?? ""
        )

        let response: APIStatusResponse = try await send(
            path: "/api/requests/feedback/submit",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "提交反馈失败")
        }
    }

    func fetchMyFeedback(baseURL: String) async throws -> [UserFeedbackItem] {
        let response: APIWrappedResponse<[UserFeedbackItem]> = try await send(
            path: "/api/requests/feedback/my",
            baseURL: baseURL
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取我的反馈失败")
        }
        return response.data ?? []
    }

    func fetchManagedFeedback(baseURL: String) async throws -> [ManagedFeedbackItem] {
        let response: APIWrappedResponse<[ManagedFeedbackItem]> = try await send(
            path: "/api/manage/feedback",
            baseURL: baseURL
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取反馈工单失败")
        }
        return response.data ?? []
    }

    func performManagedFeedbackAction(
        baseURL: String,
        feedbackID: Int,
        action: ManageFeedbackAction
    ) async throws {
        let payload = ManagedFeedbackActionPayload(id: feedbackID, action: action.rawValue)
        let response: APIStatusResponse = try await send(
            path: "/api/manage/feedback/action",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "反馈工单操作失败")
        }
    }

    func performManagedFeedbackBatch(
        baseURL: String,
        feedbackIDs: [Int],
        action: ManageFeedbackAction
    ) async throws {
        let payload = ManagedFeedbackBatchPayload(items: feedbackIDs, action: action.rawValue)
        let response: APIStatusResponse = try await send(
            path: "/api/manage/feedback/batch",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )

        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "批量反馈工单操作失败")
        }
    }

    func fetchManagedUsers(baseURL: String) async throws -> [ManagedUser] {
        let response: ManagedUsersResponse = try await send(
            path: "/api/manage/users",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取用户列表失败")
        }
        return response.data
    }

    func createManagedUser(
        baseURL: String,
        name: String,
        password: String?,
        expireDate: String?
    ) async throws {
        let payload = NewManagedUserPayload(
            name: name,
            password: password,
            expireDate: expireDate?.isEmpty == true ? nil : expireDate,
            templateUserID: nil,
            copyLibrary: true,
            copyPolicy: true,
            copyParental: true
        )
        let response: APIStatusResponse = try await send(
            path: "/api/manage/user/new",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "创建用户失败")
        }
    }

    func updateManagedUser(
        baseURL: String,
        userID: String,
        password: String? = nil,
        isDisabled: Bool? = nil,
        expireDate: String? = nil
    ) async throws {
        let payload = UpdateManagedUserPayload(
            userID: userID,
            password: password,
            isDisabled: isDisabled,
            expireDate: expireDate
        )
        let response: APIStatusResponse = try await send(
            path: "/api/manage/user/update",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "更新用户失败")
        }
    }

    func renewManagedUsers(baseURL: String, userIDs: [String], days: Int) async throws {
        let payload = ManageUsersBatchPayload(
            userIDs: userIDs,
            action: "renew",
            value: "+\(days)"
        )
        let response: APIStatusResponse = try await send(
            path: "/api/manage/users/batch",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "续期失败")
        }
    }

    func deleteManagedUser(baseURL: String, userID: String) async throws {
        let response: APIStatusResponse = try await send(
            path: "/api/manage/user/\(userID)",
            baseURL: baseURL,
            method: "DELETE"
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "删除用户失败")
        }
    }

    func generateInvites(baseURL: String, days: Int, count: Int) async throws -> [String] {
        let payload = InviteGeneratePayload(days: days, templateUserID: nil, count: count)
        let response: InviteGenerateResponse = try await send(
            path: "/api/manage/invite/gen",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "生成邀请码失败")
        }
        return response.codes ?? []
    }

    func fetchInvites(baseURL: String) async throws -> [InviteCodeItem] {
        let response: InviteListResponse = try await send(
            path: "/api/manage/invites",
            baseURL: baseURL
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "获取邀请码失败")
        }
        return response.data
    }

    func deleteInvites(baseURL: String, codes: [String]) async throws {
        let payload = InviteBatchPayload(codes: codes, action: "delete")
        let response: APIStatusResponse = try await send(
            path: "/api/manage/invites/batch",
            baseURL: baseURL,
            method: "POST",
            body: payload
        )
        guard response.isSuccess else {
            throw NetworkError.server(message: response.message ?? "删除邀请码失败")
        }
    }

    func clearSession(baseURL: String) {
        guard
            let normalized = normalizeBaseURL(baseURL),
            let cookieStorage = session.configuration.httpCookieStorage,
            let cookies = cookieStorage.cookies(for: normalized)
        else {
            return
        }

        for cookie in cookies {
            cookieStorage.deleteCookie(cookie)
        }
    }

    private func send<T: Decodable>(
        path: String,
        baseURL: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = normalizeBaseURL(baseURL) else {
            throw NetworkError.invalidBaseURL
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let existingPath = components?.path ?? ""
        components?.path = existingPath + path
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw NetworkError.invalidBaseURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Self.requestTimeout

        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        do {
            let retryCount = method.uppercased() == "GET" ? Self.maxRetryCount : 0
            let (data, response) = try await dataWithRetry(for: request, retryCount: retryCount)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw NetworkError.unauthorized
            }

            if !(200...299).contains(httpResponse.statusCode) {
                let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                throw NetworkError.server(message: message)
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.invalidResponse
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            if NetworkError.isCancellation(error) {
                throw error
            }
            throw NetworkError.transport(message: error.localizedDescription)
        }
    }

    private func dataWithRetry(
        for request: URLRequest,
        retryCount: Int
    ) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 0...max(0, retryCount) {
            do {
                return try await session.data(for: request)
            } catch {
                if NetworkError.isCancellation(error) {
                    throw error
                }

                lastError = error
                guard attempt < retryCount, shouldRetryTransportError(error) else {
                    throw error
                }

                let delay: UInt64 = UInt64((attempt + 1) * 600_000_000)
                try? await Task.sleep(nanoseconds: delay)
            }
        }

        throw lastError ?? URLError(.unknown)
    }

    private func shouldRetryTransportError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .notConnectedToInternet:
            return true
        default:
            return false
        }
    }

    private func normalizeBaseURL(_ value: String) -> URL? {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            trimmed = "http://" + trimmed
        }
        if trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        return URL(string: trimmed)
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

private struct LoginRequest: Encodable {
    let username: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case username
        case password
    }
}

private struct InviteRegisterPayload: Encodable {
    let code: String
    let username: String
    let password: String
}

private struct ManagedRequestActionPayload: Encodable {
    let tmdbID: Int
    let season: Int
    let action: String
    let rejectReason: String?

    enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdb_id"
        case season
        case action
        case rejectReason = "reject_reason"
    }
}

private struct ManagedRequestBatchPayload: Encodable {
    let items: [ManagedRequestBatchPayloadItem]
    let action: String
    let rejectReason: String?

    enum CodingKeys: String, CodingKey {
        case items
        case action
        case rejectReason = "reject_reason"
    }
}

private struct ManagedRequestBatchPayloadItem: Encodable {
    let tmdbID: Int
    let season: Int

    enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdb_id"
        case season
    }
}

private struct CalendarTTLConfigPayload: Encodable {
    let ttl: Int
}

private struct ClientBlacklistPayload: Encodable {
    let appName: String

    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
    }
}

private struct RequestPortalLoginPayload: Encodable {
    let username: String
    let password: String
}

private struct RequestSubmitPayload: Encodable {
    let tmdbID: Int
    let mediaType: String
    let title: String
    let year: String
    let posterPath: String
    let overview: String
    let seasons: [Int]

    enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdb_id"
        case mediaType = "media_type"
        case title
        case year
        case posterPath = "poster_path"
        case overview
        case seasons
    }
}

private struct RequestFeedbackSubmitPayload: Encodable {
    let itemName: String
    let issueType: String
    let description: String
    let posterPath: String

    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
        case issueType = "issue_type"
        case description
        case posterPath = "poster_path"
    }
}

private struct InsightIgnorePayloadItem: Encodable {
    let itemID: String
    let itemName: String

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case itemName = "item_name"
    }
}

private struct InsightIgnoreBatchPayload: Encodable {
    let items: [InsightIgnorePayloadItem]
}

private struct InsightUnignoreBatchPayload: Encodable {
    let itemIDs: [String]

    enum CodingKeys: String, CodingKey {
        case itemIDs = "item_ids"
    }
}

private struct GapAutoTogglePayload: Encodable {
    let enabled: Bool
}

private struct GapIgnoreEpisodePayload: Encodable {
    let seriesID: String
    let seriesName: String
    let seasonNumber: Int
    let episodeNumber: Int

    enum CodingKeys: String, CodingKey {
        case seriesID = "series_id"
        case seriesName = "series_name"
        case seasonNumber = "season_number"
        case episodeNumber = "episode_number"
    }
}

private struct GapIgnoreSeriesPayload: Encodable {
    let seriesID: String
    let seriesName: String

    enum CodingKeys: String, CodingKey {
        case seriesID = "series_id"
        case seriesName = "series_name"
    }
}

private struct GapUnignorePayload: Encodable {
    let type: String
    let id: String
}

private struct GapConfigSavePayload: Encodable {
    let clientType: String
    let clientURL: String
    let clientUser: String
    let clientPass: String

    enum CodingKeys: String, CodingKey {
        case clientType = "client_type"
        case clientURL = "client_url"
        case clientUser = "client_user"
        case clientPass = "client_pass"
    }
}

private struct GapSearchMPPayload: Encodable {
    let seriesID: String
    let seriesName: String
    let season: Int
    let episodes: [Int]

    enum CodingKeys: String, CodingKey {
        case seriesID = "series_id"
        case seriesName = "series_name"
        case season
        case episodes
    }
}

private struct GapDownloadPayload: Encodable {
    let seriesID: String
    let seriesName: String
    let tmdbID: String?
    let season: Int
    let episodes: [Int]
    let torrentInfo: [String: JSONValue]

    enum CodingKeys: String, CodingKey {
        case seriesID = "series_id"
        case seriesName = "series_name"
        case tmdbID = "tmdbid"
        case season
        case episodes
        case torrentInfo = "torrent_info"
    }
}

private struct ManagedFeedbackActionPayload: Encodable {
    let id: Int
    let action: String
}

private struct SystemSettingsSavePayload: Encodable {
    let embyHost: String
    let embyAPIKey: String
    let tmdbAPIKey: String
    let proxyURL: String
    let webhookToken: String
    let hiddenUsers: [String]
    let embyPublicURL: String
    let welcomeMessage: String
    let clientDownloadURL: String
    let moviepilotURL: String
    let moviepilotToken: String
    let pulseURL: String

    enum CodingKeys: String, CodingKey {
        case embyHost = "emby_host"
        case embyAPIKey = "emby_api_key"
        case tmdbAPIKey = "tmdb_api_key"
        case proxyURL = "proxy_url"
        case webhookToken = "webhook_token"
        case hiddenUsers = "hidden_users"
        case embyPublicURL = "emby_public_url"
        case welcomeMessage = "welcome_message"
        case clientDownloadURL = "client_download_url"
        case moviepilotURL = "moviepilot_url"
        case moviepilotToken = "moviepilot_token"
        case pulseURL = "pulse_url"
    }
}

private struct MoviePilotTestPayload: Encodable {
    let mpURL: String
    let mpToken: String

    enum CodingKeys: String, CodingKey {
        case mpURL = "mp_url"
        case mpToken = "mp_token"
    }
}

private struct TaskTranslatePayload: Encodable {
    let originalName: String
    let translatedName: String

    enum CodingKeys: String, CodingKey {
        case originalName = "original_name"
        case translatedName = "translated_name"
    }
}

private struct BotSettingsSavePayload: Encodable {
    let tgBotToken: String
    let tgChatID: String
    let enableBot: Bool
    let enableNotify: Bool
    let enableLibraryNotify: Bool
    let wecomCorpid: String
    let wecomCorpsecret: String
    let wecomAgentid: String
    let wecomTouser: String
    let wecomProxyURL: String
    let wecomToken: String
    let wecomAESKey: String

    enum CodingKeys: String, CodingKey {
        case tgBotToken = "tg_bot_token"
        case tgChatID = "tg_chat_id"
        case enableBot = "enable_bot"
        case enableNotify = "enable_notify"
        case enableLibraryNotify = "enable_library_notify"
        case wecomCorpid = "wecom_corpid"
        case wecomCorpsecret = "wecom_corpsecret"
        case wecomAgentid = "wecom_agentid"
        case wecomTouser = "wecom_touser"
        case wecomProxyURL = "wecom_proxy_url"
        case wecomToken = "wecom_token"
        case wecomAESKey = "wecom_aeskey"
    }
}

private struct ManagedFeedbackBatchPayload: Encodable {
    let items: [Int]
    let action: String
}

private struct ReportPushPayload: Encodable {
    let userID: String
    let period: String
    let theme: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case period
        case theme
    }
}

private struct NewManagedUserPayload: Encodable {
    let name: String
    let password: String?
    let expireDate: String?
    let templateUserID: String?
    let copyLibrary: Bool
    let copyPolicy: Bool
    let copyParental: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case password
        case expireDate = "expire_date"
        case templateUserID = "template_user_id"
        case copyLibrary = "copy_library"
        case copyPolicy = "copy_policy"
        case copyParental = "copy_parental"
    }
}

private struct UpdateManagedUserPayload: Encodable {
    let userID: String
    let password: String?
    let isDisabled: Bool?
    let expireDate: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case password
        case isDisabled = "is_disabled"
        case expireDate = "expire_date"
    }
}

private struct ManageUsersBatchPayload: Encodable {
    let userIDs: [String]
    let action: String
    let value: String?

    enum CodingKeys: String, CodingKey {
        case userIDs = "user_ids"
        case action
        case value
    }
}

private struct InviteGeneratePayload: Encodable {
    let days: Int
    let templateUserID: String?
    let count: Int

    enum CodingKeys: String, CodingKey {
        case days
        case templateUserID = "template_user_id"
        case count
    }
}

private struct InviteGenerateResponse: Decodable {
    let status: String
    let codes: [String]?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}

private struct InviteBatchPayload: Encodable {
    let codes: [String]
    let action: String
}
