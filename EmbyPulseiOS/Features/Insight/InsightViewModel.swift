import Foundation

@MainActor
final class InsightViewModel: ObservableObject {
    @Published var qualityStats: InsightQualityStats?
    @Published var ignores: [InsightIgnoreItem] = []

    @Published var selectedCategory: InsightCategory = .fourK
    @Published var selectedMovieIDs: Set<String> = []
    @Published var selectedIgnoreIDs: Set<String> = []

    @Published var isLoadingQuality = false
    @Published var isLoadingIgnores = false
    @Published var isOperating = false
    @Published var errorMessage: String?
    @Published var actionHint: String?

    var currentItems: [InsightMovieItem] {
        qualityStats?.movies.items(for: selectedCategory) ?? []
    }

    var selectedItems: [InsightMovieItem] {
        currentItems.filter { selectedMovieIDs.contains($0.id) }
    }

    func loadInitial(appState: AppState) async {
        errorMessage = nil
        actionHint = nil

        async let qualityTask: Void = loadQuality(appState: appState, forceRefresh: false)
        async let ignoreTask: Void = loadIgnores(appState: appState)
        _ = await (qualityTask, ignoreTask)
    }

    func loadQuality(appState: AppState, forceRefresh: Bool) async {
        isLoadingQuality = true
        errorMessage = nil

        do {
            let data = try await appState.apiClient.fetchInsightQuality(
                baseURL: appState.environment.baseURL,
                forceRefresh: forceRefresh
            )
            qualityStats = data
            selectedMovieIDs = selectedMovieIDs.filter { id in
                currentItems.contains(where: { $0.id == id })
            }
            if forceRefresh {
                actionHint = "深度重扫完成"
            }
        } catch {
            errorMessage = error.localizedDescription
            if forceRefresh {
                actionHint = nil
            }
        }

        isLoadingQuality = false
    }

    func loadIgnores(appState: AppState) async {
        isLoadingIgnores = true

        do {
            ignores = try await appState.apiClient.fetchInsightIgnores(baseURL: appState.environment.baseURL)
            selectedIgnoreIDs = selectedIgnoreIDs.filter { id in
                ignores.contains(where: { $0.itemID == id })
            }
        } catch {
            errorMessage = error.localizedDescription
            ignores = []
        }

        isLoadingIgnores = false
    }

    func switchCategory(_ category: InsightCategory) {
        selectedCategory = category
        selectedMovieIDs.removeAll()
    }

    func toggleMovieSelection(id: String) {
        if selectedMovieIDs.contains(id) {
            selectedMovieIDs.remove(id)
        } else {
            selectedMovieIDs.insert(id)
        }
    }

    func toggleIgnoreSelection(id: String) {
        if selectedIgnoreIDs.contains(id) {
            selectedIgnoreIDs.remove(id)
        } else {
            selectedIgnoreIDs.insert(id)
        }
    }

    func toggleSelectAllCurrentItems() {
        let ids = Set(currentItems.map(\.id))
        if !ids.isEmpty && selectedMovieIDs == ids {
            selectedMovieIDs.removeAll()
        } else {
            selectedMovieIDs = ids
        }
    }

    func toggleSelectAllIgnores() {
        let ids = Set(ignores.map(\.itemID))
        if !ids.isEmpty && selectedIgnoreIDs == ids {
            selectedIgnoreIDs.removeAll()
        } else {
            selectedIgnoreIDs = ids
        }
    }

    func ignoreSelectedItems(appState: AppState) async {
        let payloadItems = selectedItems.map { (itemID: $0.id, itemName: $0.name) }
        guard !payloadItems.isEmpty else {
            errorMessage = "请先选择要忽略的影片"
            return
        }

        isOperating = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.ignoreInsightItems(
                baseURL: appState.environment.baseURL,
                items: payloadItems
            )
            actionHint = "已忽略 \(payloadItems.count) 项"
            selectedMovieIDs.removeAll()
            await loadQuality(appState: appState, forceRefresh: false)
            await loadIgnores(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        isOperating = false
    }

    func restoreSelectedIgnores(appState: AppState) async {
        let ids = selectedIgnoreIDs.sorted()
        guard !ids.isEmpty else {
            errorMessage = "请先选择要恢复的条目"
            return
        }

        isOperating = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.unignoreInsightItems(
                baseURL: appState.environment.baseURL,
                itemIDs: ids
            )
            actionHint = "已恢复 \(ids.count) 项"
            selectedIgnoreIDs.removeAll()
            await loadQuality(appState: appState, forceRefresh: false)
            await loadIgnores(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        isOperating = false
    }
}
