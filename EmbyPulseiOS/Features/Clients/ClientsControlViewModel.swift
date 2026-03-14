import Foundation

@MainActor
final class ClientsControlViewModel: ObservableObject {
    @Published var blacklist: [ClientBlacklistItem] = []
    @Published var devices: [ClientDeviceItem] = []
    @Published var piePoints: [ClientChartPoint] = []
    @Published var barPoints: [ClientChartPoint] = []

    @Published var newBlacklistAppName: String = ""
    @Published var isLoading = false
    @Published var isExecutingBlock = false
    @Published var errorMessage: String?
    @Published var actionHint: String?

    func load(appState: AppState) async {
        isLoading = true
        errorMessage = nil

        async let blacklistTask: Void = loadBlacklist(appState: appState)
        async let dataTask: Void = loadClientsData(appState: appState)
        _ = await (blacklistTask, dataTask)

        isLoading = false
    }

    func loadBlacklist(appState: AppState) async {
        do {
            blacklist = try await appState.apiClient.fetchClientBlacklist(baseURL: appState.environment.baseURL)
        } catch {
            errorMessage = error.localizedDescription
            blacklist = []
        }
    }

    func loadClientsData(appState: AppState) async {
        do {
            let response = try await appState.apiClient.fetchClientsData(baseURL: appState.environment.baseURL)
            devices = response.devices
            piePoints = response.charts?.pie.points ?? []
            barPoints = response.charts?.bar.points ?? []
        } catch {
            errorMessage = error.localizedDescription
            devices = []
            piePoints = []
            barPoints = []
        }
    }

    func addBlacklist(appState: AppState) async {
        let appName = newBlacklistAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appName.isEmpty else {
            errorMessage = "请输入客户端名称"
            return
        }

        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.addClientBlacklist(
                baseURL: appState.environment.baseURL,
                appName: appName
            )
            actionHint = "已加入黑名单：\(appName)"
            newBlacklistAppName = ""
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeBlacklist(appState: AppState, appName: String) async {
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.deleteClientBlacklist(
                baseURL: appState.environment.baseURL,
                appName: appName
            )
            actionHint = "已移除黑名单：\(appName)"
            await load(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func executeBlock(appState: AppState) async {
        isExecutingBlock = true
        errorMessage = nil
        actionHint = nil

        do {
            let message = try await appState.apiClient.executeClientsBlock(baseURL: appState.environment.baseURL)
            actionHint = message
            await loadClientsData(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }

        isExecutingBlock = false
    }
}
