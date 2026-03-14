import SwiftUI
import UIKit

@main
struct EmbyPulseiOSApp: App {
    @StateObject private var appState = AppState()

    init() {
        Self.configureAppChrome()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.appearanceMode.colorScheme)
        }
    }

    private static func configureAppChrome() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabBarAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.55)
        tabBarAppearance.shadowColor = UIColor.black.withAlphaComponent(0.08)

        let itemAppearance = UITabBarItemAppearance(style: .stacked)
        itemAppearance.normal.iconColor = UIColor.secondaryLabel
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        itemAppearance.selected.iconColor = UIColor.systemIndigo
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemIndigo]

        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        tabBar.isTranslucent = true
        tabBar.tintColor = .systemIndigo
        tabBar.unselectedItemTintColor = .secondaryLabel
    }
}
