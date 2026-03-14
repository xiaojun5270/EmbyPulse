import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var serverURL = ""
    @State private var savedHint: String?

    var body: some View {
        Form {
            Section("连接") {
                TextField("服务地址", text: $serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Button("保存地址") {
                    appState.environment.baseURL = serverURL
                    savedHint = "已保存"
                }

                if let savedHint {
                    Text(savedHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("会话") {
                Button(role: .destructive) {
                    appState.logout()
                } label: {
                    Text("退出登录")
                }
            }
        }
        .navigationTitle("设置")
        .onAppear {
            serverURL = appState.environment.baseURL
        }
    }
}
