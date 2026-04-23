import Foundation
import SwiftData

/// Restaurant-specific fields. Linked from Item.restaurantDetails.
///
/// `address` is authoritative for display and geocoding. When a web
/// lookup runs we also stash the original post-provided address in
/// `postProvidedAddress` so the UI can surface a subtle mismatch hint.
@Model
final class RestaurantDetails {
    var address: String?
    var postProvidedAddress: String?
    var addressSourceRaw: String?
    var latitude: Double?
    var longitude: Double?
    var cuisine: String?
    var notableDishes: [String]

    var item: Item?

    init(
        address: String? = nil,
        postProvidedAddress: String? = nil,
        addressSource: AddressSource = .post,
        latitude: Double? = nil,
        longitude: Double? = nil,
        cuisine: String? = nil,
        notableDishes: [String] = []
    ) {
        self.address = address
        self.postProvidedAddress = postProvidedAddress
        self.addressSourceRaw = addressSource.rawValue
        self.latitude = latitude
        self.longitude = longitude
        self.cuisine = cuisine
        self.notableDishes = notableDishes
    }

    /// Typed accessor over the stored raw string. Keeping the stored
    /// column as an optional String avoids a SwiftData migration crash
    /// for records saved before this field existed.
    var addressSource: AddressSource {
        get { AddressSource(rawValue: addressSourceRaw ?? "") ?? .post }
        set { addressSourceRaw = newValue.rawValue }
    }
}

enum AddressSource: String, Codable {
    /// Address came only from the post's caption/image.
    case post
    /// Web search confirmed (matched or filled in) the post address.
    case web
    /// Web search returned a different address than the post; web wins.
    case webCorrected
    /// No address is known.
    case none
}
