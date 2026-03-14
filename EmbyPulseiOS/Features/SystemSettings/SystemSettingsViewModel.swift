import Foundation

@MainActor
final class SystemSettingsViewModel: ObservableObject {
    @Published var draft = SystemSettingsDraft()
    @Published var users: [EmbyUserOption] = []

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isTestingTMDB = false
    @Published var isTestingMP = false
    @Published var isFixingDatabase = false

    @Published var errorMessage: String?
    @Published var actionHint: String?

    func load(appState: AppState) async {
        isLoading = true
        errorMessage = nil

        async let settingsTask: Result<SystemSettingsData, Error> = fetchSettings(appState: appState)
        async let usersTask: Result<[EmbyUserOption], Error> = fetchUsers(appState: appState)

        let settingsResult = await settingsTask
        let usersResult = await usersTask

        switch settingsResult {
        case .success(let data):
            draft = SystemSettingsDraft(from: data)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }

        switch usersResult {
        case .success(let data):
            users = data
        case .failure(let error):
            if errorMessage == nil {
                errorMessage = error.localizedDescription
            }
            users = []
        }

        isLoading = false
    }

    private func fetchSettings(appState: AppState) async -> Result<SystemSettingsData, Error> {
        do {
            let data = try await appState.apiClient.fetchSystemSettings(baseURL: appState.environment.baseURL)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    private func fetchUsers(appState: AppState) async -> Result<[EmbyUserOption], Error> {
        do {
            let data = try await appState.apiClient.fetchUsers(baseURL: appState.environment.baseURL)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    func save(appState: AppState) async {
        isSaving = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.saveSystemSettings(
                baseURL: appState.environment.baseURL,
                draft: draft
            )
            actionHint = "系统设置保存成功"
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func testTMDB(appState: AppState) async {
        isTestingTMDB = true
        errorMessage = nil
        actionHint = nil

        do {
            let message = try await appState.apiClient.testTMDBConnection(baseURL: appState.environment.baseURL)
            actionHint = message
        } catch {
            errorMessage = error.localizedDescription
        }

        isTestingTMDB = false
    }

    func testMoviePilot(appState: AppState) async {
        let mpURL = draft.moviepilotURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let mpToken = draft.moviepilotToken.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !mpURL.isEmpty, !mpToken.isEmpty else {
            errorMessage = "请先填写 MoviePilot 地址和 Token"
            return
        }

        isTestingMP = true
        errorMessage = nil
        actionHint = nil

        do {
            let message = try await appState.apiClient.testMoviePilotConnection(
                baseURL: appState.environment.baseURL,
                mpURL: mpURL,
                mpToken: mpToken
            )
            actionHint = message
        } catch {
            errorMessage = error.localizedDescription
        }

        isTestingMP = false
    }

    func fixDatabase(appState: AppState) async {
        isFixingDatabase = true
        errorMessage = nil
        actionHint = nil

        do {
            let message = try await appState.apiClient.fixDatabase(baseURL: appState.environment.baseURL)
            actionHint = message
        } catch {
            errorMessage = error.localizedDescription
        }

        isFixingDatabase = false
    }

    func addHiddenUser(userID: String) {
        guard !userID.isEmpty else { return }
        if draft.hiddenUsers.contains(userID) { return }
        draft.hiddenUsers.append(userID)
    }

    func removeHiddenUser(userID: String) {
        draft.hiddenUsers.removeAll { $0 == userID }
    }

    func userName(for userID: String) -> String {
        users.first(where: { $0.userID == userID })?.userName ?? userID
    }

    func availableUsersForHiddenSelection() -> [EmbyUserOption] {
        users.filter { !draft.hiddenUsers.contains($0.userID) }
    }

    func webhookURL(baseURL: String) -> String {
        let host = normalizedBaseURL(baseURL)
        return "\(host)/api/v1/webhook?token=\(draft.webhookToken)"
    }

    private func normalizedBaseURL(_ baseURL: String) -> String {
        var value = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            value = "http://127.0.0.1:10307"
        }
        if !value.hasPrefix("http://") && !value.hasPrefix("https://") {
            value = "http://" + value
        }
        if value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }
}
