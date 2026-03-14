import Foundation
import SwiftUI

enum AppAppearanceMode: String {
    case light
    case dark

    var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isCheckingSession = true
    @Published var adminUsername: String
    @Published var appearanceMode: AppAppearanceMode

    let environment: ServerEnvironment
    let apiClient: APIClient

    private let adminNameStorageKey = "embypulse.admin.username"
    private let appearanceModeStorageKey = "embypulse.app.appearance.mode"
    private let sessionCheckTimeoutNanos: UInt64 = 8_000_000_000
    private var hasBootstrappedSession = false

    init(
        environment: ServerEnvironment? = nil,
        apiClient: APIClient = .shared
    ) {
        self.environment = environment ?? .shared
        self.apiClient = apiClient
        self.adminUsername = UserDefaults.standard.string(forKey: adminNameStorageKey) ?? "管理员"
        if let saved = UserDefaults.standard.string(forKey: appearanceModeStorageKey),
           let mode = AppAppearanceMode(rawValue: saved) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .light
        }
    }

    func bootstrapSessionIfNeeded() async {
        if hasBootstrappedSession {
            return
        }
        hasBootstrappedSession = true
        await restoreSessionIfNeeded()
    }

    func login(serverURL: String, username: String, password: String) async throws {
        environment.baseURL = serverURL
        try await apiClient.login(
            baseURL: environment.baseURL,
            username: username,
            password: password
        )
        adminUsername = username
        UserDefaults.standard.setValue(username, forKey: adminNameStorageKey)
        isAuthenticated = true
    }

    func logout() {
        apiClient.clearSession(baseURL: environment.baseURL)
        isAuthenticated = false
    }

    func refreshSession() async {
        await restoreSessionIfNeeded(force: true)
    }

    func toggleAppearance() {
        appearanceMode = appearanceMode == .dark ? .light : .dark
        UserDefaults.standard.setValue(appearanceMode.rawValue, forKey: appearanceModeStorageKey)
    }

    private func restoreSessionIfNeeded(force: Bool = false) async {
        isCheckingSession = true

        let baseURL = environment.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !force, (baseURL.isEmpty || isPlaceholderBaseURL(baseURL)) {
            isCheckingSession = false
            isAuthenticated = false
            return
        }

        do {
            let timeoutNanos = sessionCheckTimeoutNanos
            let client = apiClient
            let isValid = try await withThrowingTaskGroup(of: Bool.self) { taskGroup in
                taskGroup.addTask {
                    _ = try await client.fetchDashboard(baseURL: baseURL)
                    return true
                }
                taskGroup.addTask {
                    try await Task.sleep(nanoseconds: timeoutNanos)
                    return false
                }

                let firstResult = try await taskGroup.next() ?? false
                taskGroup.cancelAll()
                return firstResult
            }

            isAuthenticated = isValid
        } catch {
            isAuthenticated = false
        }

        isCheckingSession = false
    }

    private func isPlaceholderBaseURL(_ value: String) -> Bool {
        let normalized = value
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized == "http://127.0.0.1:10307" || normalized == "https://127.0.0.1:10307"
    }
}
