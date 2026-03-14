import Foundation

@MainActor
final class TasksCenterViewModel: ObservableObject {
    @Published var groups: [TaskGroup] = []

    @Published var isLoading = false
    @Published var operatingTaskIDs: Set<String> = []
    @Published var errorMessage: String?
    @Published var actionHint: String?

    var runningTasks: [ScheduledTask] {
        groups.flatMap(\.tasks).filter(\.isRunning)
    }

    func load(appState: AppState) async {
        isLoading = true
        errorMessage = nil

        do {
            let data = try await appState.apiClient.fetchTasks(baseURL: appState.environment.baseURL)
            groups = data.sorted { $0.title < $1.title }
        } catch {
            errorMessage = error.localizedDescription
            groups = []
        }

        isLoading = false
    }

    func start(task: ScheduledTask, appState: AppState) async {
        guard !operatingTaskIDs.contains(task.id) else { return }
        operatingTaskIDs.insert(task.id)
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.startTask(baseURL: appState.environment.baseURL, taskID: task.id)
            actionHint = "已启动任务：\(task.name)"
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        operatingTaskIDs.remove(task.id)
    }

    func stop(task: ScheduledTask, appState: AppState) async {
        guard !operatingTaskIDs.contains(task.id) else { return }
        operatingTaskIDs.insert(task.id)
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.stopTask(baseURL: appState.environment.baseURL, taskID: task.id)
            actionHint = "已停止任务：\(task.name)"
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        operatingTaskIDs.remove(task.id)
    }

    func rename(task: ScheduledTask, translatedName: String, appState: AppState) async {
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.translateTask(
                baseURL: appState.environment.baseURL,
                originalName: task.originalName,
                translatedName: translatedName
            )
            actionHint = translatedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "已恢复默认任务名"
                : "已更新任务别名"
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isOperating(taskID: String) -> Bool {
        operatingTaskIDs.contains(taskID)
    }
}
