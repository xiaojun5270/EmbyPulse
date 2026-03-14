import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isCheckingSession {
                ProgressView("正在检查会话...")
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await appState.bootstrapSessionIfNeeded()
        }
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: MainTab = .dashboard
    @State private var showingSearch = false
    @State private var dashboardCollapseProgress: CGFloat = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            tabContainer {
                DashboardView()
            }
            .tabItem {
                Label("仪表盘", systemImage: "rectangle.grid.2x2.fill")
            }
            .tag(MainTab.dashboard)

            tabContainer {
                AnalysisHubView()
            }
            .tabItem {
                Label("分析", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(MainTab.analysis)

            tabContainer {
                RequestsView()
            }
            .tabItem {
                Label("工单", systemImage: "list.bullet.clipboard")
            }
            .tag(MainTab.requests)

            tabContainer {
                UserManagementView()
            }
            .tabItem {
                Label("用户", systemImage: "person.2.fill")
            }
            .tag(MainTab.users)

            tabContainer {
                MoreHubView()
            }
            .tabItem {
                Label("更多", systemImage: "square.grid.2x2")
            }
            .tag(MainTab.more)
        }
        .safeAreaInset(edge: .top) {
            topActionBar
        }
        .onPreferenceChange(DashboardChromeProgressPreferenceKey.self) { value in
            if selectedTab == .dashboard {
                dashboardCollapseProgress = value
            }
        }
        .onChange(of: selectedTab) { tab in
            if tab != .dashboard {
                dashboardCollapseProgress = 0
            }
        }
        .sheet(isPresented: $showingSearch) {
            NavigationStack {
                LibrarySearchView()
            }
        }
    }

    private func tabContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
        }
    }

    private var topActionBar: some View {
        let progress = selectedTab == .dashboard ? min(max(dashboardCollapseProgress, 0), 1) : 0

        return HStack(spacing: 10) {
            Button {
                showingSearch = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    Text("搜索媒体库")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.16), Color.cyan.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            Text(appState.appearanceMode == .dark ? "暗黑" : "浅色")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())

            Button {
                appState.toggleAppearance()
            } label: {
                Image(systemName: appState.appearanceMode == .dark ? "sun.max.fill" : "moon.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.secondary.opacity(0.14))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(appState.appearanceMode == .dark ? "切换到浅色模式" : "切换到暗黑模式")

            AdminAccountMenu()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(appState.appearanceMode == .dark ? 0.10 : 0.34),
                                    Color.white.opacity(0.01)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            appState.appearanceMode == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.05),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(appState.appearanceMode == .dark ? 0.22 : 0.08),
                    radius: 10 + (2 * progress),
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: appState.appearanceMode == .dark
                    ? [Color(red: 0.07, green: 0.10, blue: 0.15).opacity(0.84), Color.clear]
                    : [Color.white.opacity(0.92), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Divider().opacity(0.22)
        }
    }
}

private enum MainTab: Hashable {
    case dashboard
    case analysis
    case requests
    case users
    case more
}
