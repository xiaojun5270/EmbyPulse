import Foundation

@MainActor
final class LibrarySearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [LibrarySearchItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionHint: String?

    func search(appState: AppState) async {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            results = []
            errorMessage = "请输入关键词"
            return
        }

        isLoading = true
        errorMessage = nil
        actionHint = nil

        do {
            results = try await appState.apiClient.searchLibrary(
                baseURL: appState.environment.baseURL,
                query: keyword
            )
            actionHint = results.isEmpty ? "未检索到结果" : "已检索到 \(results.count) 条结果"
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }

    func clear() {
        query = ""
        results = []
        errorMessage = nil
        actionHint = nil
    }
}
