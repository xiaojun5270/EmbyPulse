import Foundation

@MainActor
final class RequestsViewModel: ObservableObject {
    @Published var requests: [ManagedRequest] = []
    @Published var selectedRequestIDs: Set<String> = []
    @Published var isLoading = false
    @Published var isBatchProcessing = false
    @Published var processingRequestID: String?
    @Published var errorMessage: String?
    @Published var actionHint: String?

    func load(appState: AppState) async {
        isLoading = true
        errorMessage = nil

        do {
            requests = try await appState.apiClient.fetchManagedRequests(baseURL: appState.environment.baseURL)
            requests.sort { lhs, rhs in
                if lhs.status == rhs.status {
                    return lhs.createdAt ?? "" > rhs.createdAt ?? ""
                }
                return lhs.status < rhs.status
            }
            selectedRequestIDs = selectedRequestIDs.intersection(Set(requests.map(\.id)))
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func perform(
        action: ManageRequestAction,
        request: ManagedRequest,
        rejectReason: String?,
        appState: AppState
    ) async {
        processingRequestID = request.id
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.performManagedRequestAction(
                baseURL: appState.environment.baseURL,
                tmdbID: request.tmdbID,
                season: request.season,
                action: action,
                rejectReason: rejectReason
            )
            actionHint = "操作完成：\(action.title)"
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        processingRequestID = nil
    }

    func isSelected(_ request: ManagedRequest) -> Bool {
        selectedRequestIDs.contains(request.id)
    }

    func toggleSelection(for request: ManagedRequest) {
        if selectedRequestIDs.contains(request.id) {
            selectedRequestIDs.remove(request.id)
        } else {
            selectedRequestIDs.insert(request.id)
        }
    }

    func toggleSelectAll(in requests: [ManagedRequest]) {
        let ids = Set(requests.map(\.id))
        guard !ids.isEmpty else {
            selectedRequestIDs = []
            return
        }

        if ids.isSubset(of: selectedRequestIDs) {
            selectedRequestIDs.subtract(ids)
        } else {
            selectedRequestIDs.formUnion(ids)
        }
    }

    func selectedCount(in requests: [ManagedRequest]) -> Int {
        requests.reduce(0) { partialResult, request in
            partialResult + (selectedRequestIDs.contains(request.id) ? 1 : 0)
        }
    }

    func performBatch(
        action: ManageRequestAction,
        in requests: [ManagedRequest],
        rejectReason: String?,
        appState: AppState
    ) async {
        let selectedItems = requests
            .filter { selectedRequestIDs.contains($0.id) }
            .map { ManagedRequestBatchItem(tmdbID: $0.tmdbID, season: $0.season) }

        guard !selectedItems.isEmpty else {
            errorMessage = "请先选择工单"
            return
        }

        isBatchProcessing = true
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.performManagedRequestsBatch(
                baseURL: appState.environment.baseURL,
                items: selectedItems,
                action: action,
                rejectReason: rejectReason
            )
            actionHint = "批量操作完成：\(action.title)（\(selectedItems.count) 项）"
            selectedRequestIDs.subtract(selectedItems.map { "\($0.tmdbID)-\($0.season)" })
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        isBatchProcessing = false
    }
}
