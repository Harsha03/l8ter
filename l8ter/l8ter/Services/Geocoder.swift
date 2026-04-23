import Foundation
import CoreLocation

/// Thin wrapper around CLGeocoder for forward geocoding a restaurant
/// address into coordinates. Best-effort: returns nil on no match or
/// network failure rather than throwing, because geocoding is an
/// enrichment step — an item should still save even if geocoding fails.
enum Geocoder {
    /// Combine whatever address + city fields we have into one query string
    /// and ask CLGeocoder for coordinates.
    static func coordinates(address: String?, city: String?) async -> CLLocationCoordinate2D? {
        let parts = [address, city].compactMap { part -> String? in
            guard let trimmed = part?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !trimmed.isEmpty else { return nil }
            return trimmed
        }
        guard !parts.isEmpty else { return nil }
        let query = parts.joined(separator: ", ")

        do {
            let placemarks = try await CLGeocoder().geocodeAddressString(query)
            return placemarks.first?.location?.coordinate
        } catch {
            return nil
        }
    }
}
