import Foundation

@MainActor
final class ReportWorkshopViewModel: ObservableObject {
    @Published var users: [EmbyUserOption] = []
    @Published var selectedUserID: String = "all"
    @Published var selectedPeriod: ReportPeriod = .month
    @Published var selectedTheme: ReportTheme = .blackGold

    @Published var posterData: PosterData?
    @Published var previewNonce: String = UUID().uuidString

    @Published var isLoadingUsers = false
    @Published var isLoadingData = false
    @Published var isPushing = false

    @Published var errorMessage: String?
    @Published var actionHint: String?

    func loadInitial(appState: AppState) async {
        isLoadingUsers = true
        errorMessage = nil

        do {
            users = try await appState.apiClient.fetchUsers(baseURL: appState.environment.baseURL)
        } catch {
            guard !NetworkError.isCancellation(error) else {
                isLoadingUsers = false
                return
            }
            users = []
            errorMessage = error.localizedDescription
        }

        isLoadingUsers = false
        await refreshData(appState: appState)
    }

    func refreshData(appState: AppState) async {
        isLoadingData = true
        errorMessage = nil

        do {
            posterData = try await appState.apiClient.fetchPosterData(
                baseURL: appState.environment.baseURL,
                userID: selectedUserID,
                period: selectedPeriod
            )
            previewNonce = UUID().uuidString
        } catch {
            guard !NetworkError.isCancellation(error) else {
                isLoadingData = false
                return
            }
            posterData = nil
            errorMessage = error.localizedDescription
        }

        isLoadingData = false
    }

    func pushReport(appState: AppState) async {
        isPushing = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.pushReport(
                baseURL: appState.environment.baseURL,
                userID: selectedUserID,
                period: selectedPeriod,
                theme: selectedTheme
            )
            actionHint = "报表推送成功"
        } catch {
            guard !NetworkError.isCancellation(error) else {
                isPushing = false
                return
            }
            errorMessage = error.localizedDescription
        }

        isPushing = false
    }

    func previewURL(baseURL: String) -> URL? {
        guard var host = normalizeBaseURL(baseURL) else { return nil }
        host += "/api/report/preview"

        var components = URLComponents(string: host)
        components?.queryItems = [
            URLQueryItem(name: "user_id", value: selectedUserID),
            URLQueryItem(name: "period", value: selectedPeriod.rawValue),
            URLQueryItem(name: "_", value: previewNonce)
        ]
        return components?.url
    }

    func selectedUserTitle() -> String {
        if selectedUserID == "all" {
            return "全服概览"
        }
        return users.first(where: { $0.userID == selectedUserID })?.userName ?? selectedUserID
    }

    private func normalizeBaseURL(_ baseURL: String) -> String? {
        var trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            trimmed = "http://" + trimmed
        }
        if trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        return trimmed
    }
}
