import Foundation

@MainActor
final class FeedbackAdminViewModel: ObservableObject {
    @Published var feedbacks: [ManagedFeedbackItem] = []
    @Published var isLoading = false
    @Published var isOperating = false
    @Published var errorMessage: String?
    @Published var actionHint: String?

    func load(appState: AppState) async {
        isLoading = true
        errorMessage = nil

        do {
            feedbacks = try await appState.apiClient.fetchManagedFeedback(baseURL: appState.environment.baseURL)
            feedbacks.sort { lhs, rhs in
                if lhs.status == rhs.status {
                    return lhs.createdAt ?? "" > rhs.createdAt ?? ""
                }
                return lhs.status < rhs.status
            }
        } catch {
            errorMessage = error.localizedDescription
            feedbacks = []
        }

        isLoading = false
    }

    func perform(action: ManageFeedbackAction, feedbackID: Int, appState: AppState) async {
        isOperating = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.performManagedFeedbackAction(
                baseURL: appState.environment.baseURL,
                feedbackID: feedbackID,
                action: action
            )
            actionHint = "操作完成：\(action.title)"
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        isOperating = false
    }

    func performBatch(action: ManageFeedbackAction, feedbackIDs: [Int], appState: AppState) async {
        guard !feedbackIDs.isEmpty else { return }

        isOperating = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.performManagedFeedbackBatch(
                baseURL: appState.environment.baseURL,
                feedbackIDs: feedbackIDs,
                action: action
            )
            actionHint = "批量操作完成：\(action.title) (\(feedbackIDs.count)项)"
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        isOperating = false
    }
}
