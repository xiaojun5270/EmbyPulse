import SwiftUI

struct AdminAccountMenu: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Menu {
            Section("当前账号") {
                Label(appState.adminUsername, systemImage: "person.crop.circle")
                if !appState.environment.baseURL.isEmpty {
                    Text(appState.environment.baseURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("会话") {
                Button(role: .destructive) {
                    appState.logout()
                } label: {
                    Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.indigo.opacity(0.2), Color.cyan.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "person.crop.circle.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.indigo)
            }
            .frame(width: 30, height: 30)
        }
        .accessibilityLabel("管理员菜单")
    }
}
