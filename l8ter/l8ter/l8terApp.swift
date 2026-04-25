//
//  l8terApp.swift
//  l8ter
//
//  Created by Harsha Jaiganesh on 4/22/26.
//

import SwiftUI
import SwiftData

@main
struct l8terApp: App {
    let container: ModelContainer

    init() {
        container = Self.makeContainer()
        ProximityManager.shared.configure(container: container)
        if ProximityManager.shared.isEnabled {
            ProximityManager.shared.refreshGeofences()
        }
    }

    /// Build the SwiftData container, self-healing against incompatible
    /// on-disk stores left behind by schema changes during development.
    /// If the initial load fails, we delete the store files at the known
    /// URL and try again with a fresh store.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Item.self,
            RestaurantDetails.self,
            MovieDetails.self,
            ShowDetails.self,
            CustomCategory.self
        ])

        let storeURL = defaultStoreURL()
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Incompatible store from an older schema. Wipe and retry.
            // This is acceptable during personal dev; revisit once
            // there's real user data worth preserving.
            print("⚠️ ModelContainer load failed (\(error)); deleting store and retrying.")
            removeStoreFiles(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("ModelContainer retry failed: \(error)")
            }
        }
    }

    private static func defaultStoreURL() -> URL {
        let fm = FileManager.default
        let appSupport = try! fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupport.appendingPathComponent("l8ter.store")
    }

    private static func removeStoreFiles(at url: URL) {
        let fm = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            let target = URL(fileURLWithPath: url.path + suffix)
            try? fm.removeItem(at: target)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .tint(Color.accent)
        }
        .modelContainer(container)
    }
}
