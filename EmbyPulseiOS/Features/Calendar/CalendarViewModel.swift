import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var weekly: CalendarWeeklyResponse?
    @Published var isLoading = false
    @Published var isSavingConfig = false
    @Published var errorMessage: String?
    @Published var actionHint: String?
    @Published var weekOffset = 0
    @Published var selectedTTL: Int = 86400

    var ttlOptions: [Int] {
        var values = Set([3600, 21600, 43200, 86400, 172800, 604800])
        if selectedTTL > 0 {
            values.insert(selectedTTL)
        }
        if let current = weekly?.currentTTL, current > 0 {
            values.insert(current)
        }
        return values.sorted()
    }

    func load(appState: AppState, forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await appState.apiClient.fetchCalendarWeekly(
                baseURL: appState.environment.baseURL,
                offset: weekOffset,
                refresh: forceRefresh
            )

            weekly = response
            if let currentTTL = response.currentTTL, currentTTL > 0 {
                selectedTTL = currentTTL
            }
            if let error = response.error, !error.isEmpty {
                errorMessage = error
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func moveWeek(by delta: Int, appState: AppState) async {
        weekOffset += delta
        await load(appState: appState)
    }

    func resetToCurrentWeek(appState: AppState) async {
        weekOffset = 0
        await load(appState: appState)
    }

    func saveTTLConfig(appState: AppState) async {
        guard selectedTTL > 0 else {
            errorMessage = "TTL 必须大于 0"
            return
        }

        isSavingConfig = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.updateCalendarConfig(
                baseURL: appState.environment.baseURL,
                ttl: selectedTTL
            )
            actionHint = "缓存策略已更新"
            await load(appState: appState, forceRefresh: true)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSavingConfig = false
    }
}
