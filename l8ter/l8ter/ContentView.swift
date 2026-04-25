import SwiftUI
import SwiftData
import UIKit

/// Root tab bar. Saved items, capture, map, review queue, and debug tools.
/// The tab bar appearance is configured globally to match the design
/// system: dark surface, hairline top border, purple accent for active.
struct ContentView: View {
    @Query(filter: #Predicate<Item> { !$0.isArchived && $0.needsReview })
    private var reviewItems: [Item]

    init() {
        Self.configureTabBarAppearance()
    }

    var body: some View {
        TabView {
            ItemListView()
                .tabItem { Label("Saved", systemImage: "tray.full") }
            CaptureView()
                .tabItem { Label("Add", systemImage: "plus.circle") }
            RestaurantsMapView()
                .tabItem { Label("Map", systemImage: "map") }
            ReviewQueueView()
                .tabItem { Label("Review", systemImage: "exclamationmark.bubble") }
                .badge(reviewItems.count)
            DebugMenuView()
                .tabItem { Label("Debug", systemImage: "wrench.and.screwdriver") }
        }
    }

    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.bgBase)
        appearance.shadowColor = UIColor(Color.borderHairline)

        let active = UIColor(Color.accent)
        let inactive = UIColor(Color.textDisabled)

        for state in [appearance.stackedLayoutAppearance,
                      appearance.inlineLayoutAppearance,
                      appearance.compactInlineLayoutAppearance] {
            state.normal.iconColor = inactive
            state.normal.titleTextAttributes = [.foregroundColor: inactive]
            state.selected.iconColor = active
            state.selected.titleTextAttributes = [.foregroundColor: active]
            state.normal.badgeBackgroundColor = active
            state.selected.badgeBackgroundColor = active
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

/// Phase 1a dev tools, kept accessible while the real app grows.
struct DebugMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Settings") { SettingsView() }
                NavigationLink("Manage Categories") { ManageCategoriesView() }
                NavigationLink("oEmbed Test") { OEmbedDebugView() }
                NavigationLink("Extract Test") { ExtractDebugView() }
            }
            .navigationTitle("Debug")
        }
    }
}

#Preview {
    ContentView()
}
