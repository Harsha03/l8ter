import Foundation
import CoreLocation
import UserNotifications
import SwiftData

/// Manages geofences for saved restaurants + posts local notifications
/// on entry.
///
/// iOS caps active geofences at 20 per app. When there are more saved
/// restaurants than that, we keep the nearest 20 to the user's current
/// location and refresh the set on significant location change.
///
/// Battery strategy:
/// - Never request continuous `startUpdatingLocation`
/// - Only rely on region monitoring + `startMonitoringSignificantLocationChanges`
@MainActor
final class ProximityManager: NSObject {
    static let shared = ProximityManager()

    private let locationManager = CLLocationManager()
    private var modelContainer: ModelContainer?
    private var lastKnownLocation: CLLocation?

    /// UserDefaults key for the on/off toggle.
    static let enabledKey = "proximityAlertsEnabled"

    /// Radius in meters for each restaurant geofence.
    private let regionRadius: CLLocationDistance = 150

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    /// Called once from the app. Supplies the model container so region
    /// callbacks can look up restaurant details for notification text.
    func configure(container: ModelContainer) {
        self.modelContainer = container
    }

    /// Turn proximity alerts on. Prompts for location + notification
    /// permissions, then registers geofences.
    func enable() async {
        UserDefaults.standard.set(true, forKey: Self.enabledKey)

        // Notification permission
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])

        // Location permission: request WhenInUse first; the system then
        // lets the user upgrade to Always when a region fires in background.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }

        locationManager.startMonitoringSignificantLocationChanges()
        refreshGeofences()
    }

    /// Turn proximity alerts off. Deregisters every region.
    func disable() {
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
        locationManager.stopMonitoringSignificantLocationChanges()
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }

    /// Recompute which 20 restaurants to monitor based on the user's
    /// current location (or most-recently-added, when no fix is known).
    func refreshGeofences() {
        guard isEnabled, let container = modelContainer else { return }

        // Clear out existing l8ter-owned regions.
        for region in locationManager.monitoredRegions {
            if region.identifier.hasPrefix("l8ter.") {
                locationManager.stopMonitoring(for: region)
            }
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate<Item> { !$0.isArchived },
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        guard let items = try? context.fetch(descriptor) else { return }

        let candidates: [(Item, CLLocationCoordinate2D)] = items.compactMap { item in
            guard item.isRestaurant,
                  let lat = item.restaurantDetails?.latitude,
                  let lon = item.restaurantDetails?.longitude else { return nil }
            return (item, CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }

        // Pick the nearest 20 to current location when we have it.
        let ranked: [(Item, CLLocationCoordinate2D)]
        if let here = lastKnownLocation {
            ranked = candidates.sorted { a, b in
                let da = CLLocation(latitude: a.1.latitude, longitude: a.1.longitude)
                    .distance(from: here)
                let db = CLLocation(latitude: b.1.latitude, longitude: b.1.longitude)
                    .distance(from: here)
                return da < db
            }
        } else {
            ranked = candidates
        }

        for (item, coord) in ranked.prefix(20) {
            let region = CLCircularRegion(
                center: coord,
                radius: regionRadius,
                identifier: "l8ter.\(item.id.uuidString)"
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            locationManager.startMonitoring(for: region)
        }
    }

    private func postNotification(for regionID: String) {
        guard let container = modelContainer,
              let uuid = uuidFromRegion(regionID) else { return }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate<Item> { $0.id == uuid }
        )
        guard let item = try? context.fetch(descriptor).first else { return }

        let content = UNMutableNotificationContent()
        content.title = "You're near \(item.title)"
        let dishes = item.restaurantDetails?.notableDishes ?? []
        if !dishes.isEmpty {
            content.body = "You saved this for: \(dishes.prefix(3).joined(separator: ", "))"
        } else if let cuisine = item.restaurantDetails?.cuisine {
            content.body = "Saved \(cuisine) spot"
        } else {
            content.body = "One of your saved restaurants is nearby."
        }
        content.sound = .default
        content.userInfo = ["itemID": item.id.uuidString]

        let request = UNNotificationRequest(
            identifier: regionID,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func uuidFromRegion(_ identifier: String) -> UUID? {
        guard identifier.hasPrefix("l8ter.") else { return nil }
        let raw = String(identifier.dropFirst("l8ter.".count))
        return UUID(uuidString: raw)
    }
}

extension ProximityManager: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.lastKnownLocation = loc
            self.refreshGeofences()
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        Task { @MainActor in
            self.postNotification(for: region.identifier)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        Task { @MainActor in
            // After WhenInUse granted, try to upgrade to Always so
            // region entries still fire in background.
            if manager.authorizationStatus == .authorizedWhenInUse {
                manager.requestAlwaysAuthorization()
            }
            if self.isEnabled,
               manager.authorizationStatus == .authorizedAlways
                || manager.authorizationStatus == .authorizedWhenInUse {
                manager.startMonitoringSignificantLocationChanges()
                self.refreshGeofences()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        // Silent: monitoring is best-effort.
    }
}
