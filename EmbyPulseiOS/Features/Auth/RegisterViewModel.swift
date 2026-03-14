import Foundation

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var serverURL: String
    @Published var inviteCode = ""
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var welcomeMessage: String?
    @Published var registeredServerURL: String?

    init(serverURL: String) {
        self.serverURL = serverURL
    }

    var canSubmit: Bool {
        !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !isSubmitting
    }

    var preferredServerURL: String {
        let candidate = registeredServerURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let candidate, !candidate.isEmpty {
            return candidate
        }
        return serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func submit(appState: AppState) async -> Bool {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !user.isEmpty, !password.isEmpty else {
            errorMessage = "请完整填写邀请码和账号信息"
            return false
        }
        guard password == confirmPassword else {
            errorMessage = "两次密码输入不一致"
            return false
        }

        isSubmitting = true
        errorMessage = nil
        successMessage = nil

        do {
            let response = try await appState.apiClient.registerWithInvite(
                baseURL: serverURL,
                code: code,
                username: user,
                password: password
            )
            successMessage = "注册成功"
            welcomeMessage = response.welcomeMessage
            registeredServerURL = response.serverURL
            password = ""
            confirmPassword = ""
            isSubmitting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        }
    }
}
