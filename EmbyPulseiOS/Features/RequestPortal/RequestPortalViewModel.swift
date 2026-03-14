import Foundation

@MainActor
final class RequestPortalViewModel: ObservableObject {
    @Published var portalUser: RequestPortalUser?
    @Published var loginUsername: String = ""
    @Published var loginPassword: String = ""
    @Published var isAuthenticating = false

    @Published var trending: RequestTrendingGroups = .empty
    @Published var isLoadingTrending = false

    @Published var searchQuery: String = ""
    @Published var searchResults: [RequestMediaItem] = []
    @Published var isSearching = false

    @Published var myRequests: [UserRequestItem] = []
    @Published var isLoadingMyRequests = false
    @Published var myFeedbacks: [UserFeedbackItem] = []
    @Published var isLoadingMyFeedbacks = false

    @Published var activeMedia: RequestMediaItem?
    @Published var tvSeasons: [TVSeasonInfo] = []
    @Published var selectedSeasons: Set<Int> = []
    @Published var isLoadingSeasons = false
    @Published var isSubmittingRequest = false

    @Published var feedbackItemName: String = ""
    @Published var feedbackIssueType: String = "缺少字幕"
    @Published var feedbackDescription: String = ""
    @Published var feedbackPosterPath: String = ""
    @Published var isSubmittingFeedback = false

    @Published var errorMessage: String?
    @Published var actionHint: String?

    let feedbackIssueOptions: [String] = [
        "缺少字幕",
        "字幕错位",
        "视频卡顿/花屏",
        "清晰度太低",
        "音轨无声/音画不同步",
        "其他问题"
    ]

    var isPortalLoggedIn: Bool {
        portalUser != nil
    }

    var availableTVSeasonNumbers: [Int] {
        tvSeasons
            .filter { !$0.existsLocally }
            .map(\.seasonNumber)
            .sorted()
    }

    var canSubmitActiveRequest: Bool {
        guard let activeMedia else { return false }
        if activeMedia.mediaType == "movie" {
            return activeMedia.localStatus != 2
        }

        let available = Set(availableTVSeasonNumbers)
        guard !available.isEmpty else { return false }
        return !selectedSeasons.isEmpty && selectedSeasons.isSubset(of: available)
    }

    func loadInitial(appState: AppState) async {
        await checkSession(appState: appState)

        async let trendingTask: Void = loadTrending(appState: appState)
        if isPortalLoggedIn {
            async let requestsTask: Void = loadMyRequests(appState: appState)
            async let feedbackTask: Void = loadMyFeedbacks(appState: appState)
            _ = await (trendingTask, requestsTask, feedbackTask)
        } else {
            _ = await trendingTask
        }
    }

    func checkSession(appState: AppState) async {
        do {
            let response = try await appState.apiClient.fetchRequestPortalSession(baseURL: appState.environment.baseURL)
            if response.isSuccess, let user = response.user {
                portalUser = user
                if loginUsername.isEmpty {
                    loginUsername = user.name
                }
            } else {
                portalUser = nil
            }
        } catch {
            portalUser = nil
        }
    }

    func login(appState: AppState) async -> Bool {
        let username = loginUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = loginPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "请输入用户名和密码"
            return false
        }

        isAuthenticating = true
        errorMessage = nil
        actionHint = nil

        do {
            let user = try await appState.apiClient.requestPortalLogin(
                baseURL: appState.environment.baseURL,
                username: username,
                password: password
            )
            portalUser = user
            loginPassword = ""
            actionHint = "求片会话已登录"
            await loadMyRequests(appState: appState)
            isAuthenticating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticating = false
            return false
        }
    }

    func logout(appState: AppState) async {
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.requestPortalLogout(baseURL: appState.environment.baseURL)
            portalUser = nil
            myRequests = []
            myFeedbacks = []
            activeMedia = nil
            tvSeasons = []
            selectedSeasons = []
            actionHint = "已退出求片会话"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTrending(appState: AppState) async {
        isLoadingTrending = true
        errorMessage = nil

        do {
            trending = try await appState.apiClient.fetchRequestTrending(baseURL: appState.environment.baseURL)
        } catch {
            errorMessage = error.localizedDescription
            trending = .empty
        }

        isLoadingTrending = false
    }

    func search(appState: AppState) async {
        guard isPortalLoggedIn else {
            errorMessage = "请先登录求片系统"
            return
        }

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        errorMessage = nil
        actionHint = nil

        do {
            searchResults = try await appState.apiClient.searchRequestMedia(
                baseURL: appState.environment.baseURL,
                query: query
            )
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }

        isSearching = false
    }

    func loadMyRequests(appState: AppState) async {
        guard isPortalLoggedIn else {
            myRequests = []
            return
        }

        isLoadingMyRequests = true
        errorMessage = nil

        do {
            myRequests = try await appState.apiClient.fetchMyUserRequests(baseURL: appState.environment.baseURL)
        } catch {
            errorMessage = error.localizedDescription
            myRequests = []
        }

        isLoadingMyRequests = false
    }

    func loadMyFeedbacks(appState: AppState) async {
        guard isPortalLoggedIn else {
            myFeedbacks = []
            return
        }

        isLoadingMyFeedbacks = true
        errorMessage = nil

        do {
            myFeedbacks = try await appState.apiClient.fetchMyFeedback(baseURL: appState.environment.baseURL)
        } catch {
            errorMessage = error.localizedDescription
            myFeedbacks = []
        }

        isLoadingMyFeedbacks = false
    }

    func openSubmitSheet(for media: RequestMediaItem, appState: AppState) async {
        guard isPortalLoggedIn else {
            errorMessage = "请先登录求片系统"
            return
        }

        activeMedia = media
        tvSeasons = []
        selectedSeasons = []
        errorMessage = nil
        actionHint = nil

        guard media.mediaType == "tv" else {
            return
        }

        isLoadingSeasons = true
        do {
            tvSeasons = try await appState.apiClient.fetchTVSeasons(
                baseURL: appState.environment.baseURL,
                tmdbID: media.tmdbID
            )
            let available = tvSeasons.filter { !$0.existsLocally }.map(\.seasonNumber)
            selectedSeasons = Set(available)
        } catch {
            errorMessage = error.localizedDescription
            tvSeasons = []
            selectedSeasons = []
        }
        isLoadingSeasons = false
    }

    func toggleSeason(_ season: Int) {
        if selectedSeasons.contains(season) {
            selectedSeasons.remove(season)
        } else {
            selectedSeasons.insert(season)
        }
    }

    func prepareFeedback(itemName: String, posterPath: String?) {
        feedbackItemName = itemName
        feedbackPosterPath = posterPath ?? ""
        if feedbackIssueOptions.contains(feedbackIssueType) == false {
            feedbackIssueType = "缺少字幕"
        }
    }

    func submitFeedback(appState: AppState) async -> Bool {
        guard isPortalLoggedIn else {
            errorMessage = "请先登录求片系统"
            return false
        }

        let itemName = feedbackItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !itemName.isEmpty else {
            errorMessage = "请填写资源名称"
            return false
        }

        let issueType = feedbackIssueType.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = feedbackDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        isSubmittingFeedback = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.submitRequestFeedback(
                baseURL: appState.environment.baseURL,
                itemName: itemName,
                issueType: issueType.isEmpty ? "其他问题" : issueType,
                description: description,
                posterPath: feedbackPosterPath
            )
            actionHint = "报错已提交"
            feedbackDescription = ""
            await loadMyFeedbacks(appState: appState)
            isSubmittingFeedback = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmittingFeedback = false
            return false
        }
    }

    func toggleSelectAllSeasons() {
        let all = Set(availableTVSeasonNumbers)
        if all.isEmpty {
            selectedSeasons = []
            return
        }
        if selectedSeasons == all {
            selectedSeasons = []
        } else {
            selectedSeasons = all
        }
    }

    func submitActiveRequest(appState: AppState) async -> Bool {
        guard let media = activeMedia else { return false }
        guard canSubmitActiveRequest else {
            errorMessage = media.mediaType == "tv" ? "请至少选择一季" : "该资源已在库"
            return false
        }

        let seasons = media.mediaType == "tv" ? selectedSeasons.sorted() : [0]

        isSubmittingRequest = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.submitUserRequest(
                baseURL: appState.environment.baseURL,
                media: media,
                seasons: seasons
            )
            actionHint = "求片提交成功"
            activeMedia = nil
            tvSeasons = []
            selectedSeasons = []
            await loadMyRequests(appState: appState)
            isSubmittingRequest = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmittingRequest = false
            return false
        }
    }

    func dismissSubmitSheet() {
        activeMedia = nil
        tvSeasons = []
        selectedSeasons = []
        isLoadingSeasons = false
        isSubmittingRequest = false
    }
}

private extension RequestTrendingGroups {
    static let empty = RequestTrendingGroups(
        movies: [],
        tv: [],
        topMovies: [],
        topTV: []
    )
}
