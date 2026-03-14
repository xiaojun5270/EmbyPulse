import Foundation

@MainActor
final class HistoryTrendViewModel: ObservableObject {
    @Published var users: [EmbyUserOption] = []
    @Published var selectedUserID: String = "all"
    @Published var category: TopMoviesCategory = .all
    @Published var period: TopMoviesPeriod = .year
    @Published var sortBy: TopMoviesSort = .count

    @Published var rankingItems: [TopMovieItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadInitial(appState: AppState) async {
        async let usersTask: Void = loadUsers(appState: appState)
        async let rankingTask: Void = refreshRanking(appState: appState)
        _ = await (usersTask, rankingTask)
    }

    func loadUsers(appState: AppState) async {
        do {
            users = try await appState.apiClient.fetchUsers(baseURL: appState.environment.baseURL)
        } catch {
            guard !NetworkError.isCancellation(error) else { return }
            users = []
        }
    }

    func refreshRanking(appState: AppState) async {
        isLoading = true
        errorMessage = nil
        do {
            rankingItems = try await appState.apiClient.fetchTopMovies(
                baseURL: appState.environment.baseURL,
                userID: selectedUserID,
                category: category,
                sortBy: sortBy,
                period: period
            )
        } catch {
            guard !NetworkError.isCancellation(error) else {
                isLoading = false
                return
            }
            rankingItems = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
