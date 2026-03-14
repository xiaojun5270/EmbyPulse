import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RegisterViewModel

    private let onApplyToLogin: ((String, String) -> Void)?

    init(
        defaultServerURL: String,
        onApplyToLogin: ((String, String) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: RegisterViewModel(serverURL: defaultServerURL))
        self.onApplyToLogin = onApplyToLogin
    }

    var body: some View {
        Form {
            Section("服务与邀请码") {
                TextField("服务地址", text: $viewModel.serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                TextField("邀请码", text: $viewModel.inviteCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("账号信息") {
                TextField("用户名", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("密码", text: $viewModel.password)
                SecureField("确认密码", text: $viewModel.confirmPassword)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task { _ = await viewModel.submit(appState: appState) }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("提交注册")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmit)
            }

            if let success = viewModel.successMessage {
                Section("注册结果") {
                    Text(success)
                        .font(.headline)
                        .foregroundStyle(.green)

                    if let welcome = viewModel.welcomeMessage, !welcome.isEmpty {
                        Text(welcome)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let serverURL = viewModel.registeredServerURL, !serverURL.isEmpty {
                        Text("推荐访问地址：\(serverURL)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let onApplyToLogin {
                        Button("回到登录并填充账号") {
                            onApplyToLogin(viewModel.preferredServerURL, viewModel.username)
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle("邀请码注册")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
    }
}
