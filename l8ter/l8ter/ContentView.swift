import SwiftUI
import SwiftData

/// Root tab bar. Saved items, capture, map, review queue, and debug tools.
struct ContentView: View {
    @Query(filter: #Predicate<Item> { !$0.isArchived && $0.needsReview })
    private var reviewItems: [Item]

    var body: some View {
        TabView {
            ItemListView()
                .tabItem {
                    Label("Saved", systemImage: "tray.full")
                }
            CaptureView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
            RestaurantsMapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            ReviewQueueView()
                .tabItem {
                    Label("Review", systemImage: "exclamationmark.bubble")
                }
                .badge(reviewItems.count)
            DebugMenuView()
                .tabItem {
                    Label("Debug", systemImage: "wrench.and.screwdriver")
                }
        }
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
