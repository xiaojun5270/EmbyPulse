import Foundation

@MainActor
final class BotConfigViewModel: ObservableObject {
    @Published var draft = BotSettingsDraft()

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isTestingTelegram = false
    @Published var isTestingWeCom = false

    @Published var errorMessage: String?
    @Published var actionHint: String?

    func load(appState: AppState) async {
        isLoading = true
        errorMessage = nil

        do {
            let settings = try await appState.apiClient.fetchBotSettings(baseURL: appState.environment.baseURL)
            draft = BotSettingsDraft(from: settings)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func save(appState: AppState, silent: Bool = false) async -> Bool {
        isSaving = true
        errorMessage = nil
        if !silent {
            actionHint = nil
        }

        do {
            try await appState.apiClient.saveBotSettings(
                baseURL: appState.environment.baseURL,
                draft: draft
            )
            if !silent {
                actionHint = "配置保存成功"
            }
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }

    func testTelegram(appState: AppState) async {
        isTestingTelegram = true
        errorMessage = nil
        actionHint = nil

        let saved = await save(appState: appState, silent: true)
        guard saved else {
            isTestingTelegram = false
            return
        }

        do {
            try await appState.apiClient.testBotConnection(baseURL: appState.environment.baseURL)
            actionHint = "Telegram 测试消息发送成功"
        } catch {
            errorMessage = error.localizedDescription
        }

        isTestingTelegram = false
    }

    func testWeCom(appState: AppState) async {
        isTestingWeCom = true
        errorMessage = nil
        actionHint = nil

        let saved = await save(appState: appState, silent: true)
        guard saved else {
            isTestingWeCom = false
            return
        }

        do {
            try await appState.apiClient.testWeComConnection(baseURL: appState.environment.baseURL)
            actionHint = "企业微信测试消息发送成功"
        } catch {
            errorMessage = error.localizedDescription
        }

        isTestingWeCom = false
    }

    func telegramWebhookURL(baseURL: String) -> String {
        let host = normalizedBaseURL(baseURL)
        return "\(host)/api/v1/webhook?token=\(draft.webhookToken)"
    }

    func wecomWebhookURL(baseURL: String) -> String {
        let host = normalizedBaseURL(baseURL)
        return "\(host)/api/bot/wecom_webhook"
    }

    private func normalizedBaseURL(_ baseURL: String) -> String {
        var value = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return "http://localhost"
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
