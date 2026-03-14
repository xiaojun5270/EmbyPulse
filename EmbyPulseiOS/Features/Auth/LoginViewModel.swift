import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var serverURL: String
    @Published var username = ""
    @Published var password = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    init(serverURL: String? = nil) {
        self.serverURL = serverURL ?? ServerEnvironment.shared.baseURL
    }

    func submit(appState: AppState) async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "请输入用户名和密码"
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            try await appState.login(
                serverURL: serverURL,
                username: username,
                password: password
            )
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
