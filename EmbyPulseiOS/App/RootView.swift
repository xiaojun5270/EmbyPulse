import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isCheckingSession {
                ProgressView("Checking session...")
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
                Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
            }
            .tag(MainTab.dashboard)

            tabContainer {
                AnalysisHubView()
            }
            .tabItem {
                Label("Analysis", systemImage: "chart.xyaxis.line")
            }
            .tag(MainTab.analysis)

            tabContainer {
                RequestsView()
            }
            .tabItem {
                Label("Requests", systemImage: "text.bubble.fill")
            }
            .tag(MainTab.requests)

            tabContainer {
                UserManagementView()
            }
            .tabItem {
                Label("Users", systemImage: "person.3.fill")
            }
            .tag(MainTab.users)

            tabContainer {
                MoreHubView()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle.fill")
            }
            .tag(MainTab.more)
        }
        .tint(.indigo)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarColorScheme(appState.appearanceMode == .dark ? .dark : .light, for: .tabBar)
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
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))

                    Text("Search Library")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(chipBackground(tint: .indigo))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            Text(appState.appearanceMode == .dark ? "Dark" : "Light")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(chipBackground(tint: .secondary))
                .clipShape(Capsule())

            Button {
                appState.toggleAppearance()
            } label: {
                Image(systemName: appState.appearanceMode == .dark ? "sun.max.fill" : "moon.stars.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(chipBackground(tint: .secondary))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(appState.appearanceMode == .dark ? "Switch to light mode" : "Switch to dark mode")

            AdminAccountMenu()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(appState.appearanceMode == .dark ? 0.08 : 0.32),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
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
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(
            LinearGradient(
                colors: appState.appearanceMode == .dark
                    ? [Color(red: 0.07, green: 0.10, blue: 0.15).opacity(0.80), Color.clear]
                    : [Color.white.opacity(0.88), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Divider().opacity(0.18)
        }
    }

    private func chipBackground(tint: Color) -> some View {
        ZStack {
            tint.opacity(appState.appearanceMode == .dark ? 0.18 : 0.10)
            Color.white.opacity(appState.appearanceMode == .dark ? 0.04 : 0.36)
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
