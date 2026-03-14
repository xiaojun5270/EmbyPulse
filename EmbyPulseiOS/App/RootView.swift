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
        let compact = progress > 0.72

        return HStack(spacing: 10 - (2 * progress)) {
            Button {
                showingSearch = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    if !compact {
                        Text("搜索媒体库")
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, compact ? 10 : 12)
                .padding(.vertical, compact ? 8 : 9)
                .background(
                    LinearGradient(
                        colors: [
                            Color.indigo.opacity(0.16 + (0.10 * progress)),
                            Color.cyan.opacity(0.12 + (0.08 * progress))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if compact {
                Text("仪表盘")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(appState.appearanceMode == .dark ? 0.10 : 0.06))
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale))
            }

            Spacer(minLength: max(4, 8 - (4 * progress)))

            if !compact {
                Text(appState.appearanceMode == .dark ? "暗黑" : "浅色")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }

            Button {
                appState.toggleAppearance()
            } label: {
                Image(systemName: appState.appearanceMode == .dark ? "sun.max.fill" : "moon.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: compact ? 30 : 34, height: compact ? 30 : 34)
                    .background(Color.secondary.opacity(0.14 + (0.04 * progress)))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(appState.appearanceMode == .dark ? "切换到浅色模式" : "切换到暗黑模式")

            AdminAccountMenu()
                .scaleEffect(1 - (0.08 * progress))
        }
        .padding(compact ? 8 : 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            appState.appearanceMode == .dark ? Color.white.opacity(0.10 + (0.02 * progress)) : Color.black.opacity(0.05 + (0.01 * progress)),
                            lineWidth: 1
                        )
                )
                .overlay(alignment: .topLeading) {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(appState.appearanceMode == .dark ? 0.12 : 0.36),
                            Color.white.opacity(0.01)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .shadow(
                    color: Color.black.opacity(appState.appearanceMode == .dark ? 0.22 : 0.06 + (0.03 * progress)),
                    radius: 8 + (4 * progress),
                    x: 0,
                    y: 4 + (2 * progress)
                )
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: appState.appearanceMode == .dark
                    ? [Color(red: 0.07, green: 0.10, blue: 0.15).opacity(0.82 + (0.08 * progress)), Color.clear]
                    : [Color.white.opacity(0.9 + (0.08 * progress)), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Divider().opacity(0.22)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.84), value: compact)
        .animation(.easeInOut(duration: 0.18), value: progress)
    }

}

private enum MainTab: Hashable {
    case dashboard
    case analysis
    case requests
    case users
    case more
}
