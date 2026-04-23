import Foundation
import CoreLocation
import SwiftData

/// Orchestrates persisting a captured reel:
///   ExtractionResult + oEmbed + sourceURL → thumbnail + geocode → SwiftData insert.
///
/// All steps except the SwiftData insert are best-effort. The Item is
/// still saved if the thumbnail download or geocode fails — we just
/// record what we have and flag `needsReview` when appropriate.
enum ItemSaver {
    /// Confidence threshold below which an item is flagged for async review.
    static let reviewThreshold: Double = 0.5

    @MainActor
    static func save(
        extraction: ExtractionResult,
        oEmbed: TikTokOEmbedResponse,
        sourceURL: String,
        platform: String = "tiktok",
        context: ModelContext
    ) async throws {
        guard let url = URL(string: sourceURL) else {
            throw NSError(
                domain: "ItemSaver",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid source URL"]
            )
        }

        let itemID = UUID()

        var thumbnailPath: String?
        if let thumbURLString = oEmbed.thumbnailURL,
           let thumbURL = URL(string: thumbURLString) {
            thumbnailPath = try? await ThumbnailStore.download(from: thumbURL, itemID: itemID)
        }

        let item = Item(
            id: itemID,
            sourceURL: url,
            sourcePlatform: platform,
            sourceAuthor: oEmbed.authorUniqueID ?? oEmbed.authorName,
            caption: oEmbed.title,
            thumbnailPath: thumbnailPath,
            category: extraction.category,
            title: extraction.title,
            summary: extraction.summary,
            aiConfidence: extraction.confidence,
            needsReview: extraction.confidence < reviewThreshold
                || extraction.category == BuiltInCategory.uncategorized.rawValue
        )

        if extraction.category == BuiltInCategory.movie.rawValue, let m = extraction.movie {
            let web = try? await MediaLookup.lookupMovie(from: m)
            let details = MovieDetails(
                year: web?.year ?? m.year,
                director: web?.director ?? m.director,
                genre: web?.genre ?? m.genre,
                whereToWatch: web?.whereToWatch ?? m.whereToWatch
            )
            item.movieDetails = details
            context.insert(details)
            if let web, let webTitle = web.title, !webTitle.isEmpty {
                item.title = webTitle
            }
        } else if extraction.category == BuiltInCategory.show.rawValue, let s = extraction.show {
            let web = try? await MediaLookup.lookupShow(from: s)
            let details = ShowDetails(
                creator: web?.creator ?? s.creator,
                network: web?.network ?? s.network,
                genre: web?.genre ?? s.genre,
                whereToWatch: web?.whereToWatch ?? s.whereToWatch
            )
            item.showDetails = details
            context.insert(details)
            if let web, let webTitle = web.title, !webTitle.isEmpty {
                item.title = webTitle
            }
        } else if extraction.category == BuiltInCategory.restaurant.rawValue, let r = extraction.restaurant {
            let resolved = await resolveAddress(
                extracted: r,
                authorHandle: oEmbed.authorUniqueID ?? oEmbed.authorName
            )
            let coord = await Geocoder.coordinates(
                address: resolved.address,
                city: resolved.city
            )
            let details = RestaurantDetails(
                address: resolved.address,
                postProvidedAddress: r.address,
                addressSource: resolved.source,
                latitude: coord?.latitude,
                longitude: coord?.longitude,
                cuisine: r.cuisine,
                notableDishes: r.notableDishes
            )
            item.restaurantDetails = details
            context.insert(details)
        }

        context.insert(item)
        try context.save()

        if extraction.category == BuiltInCategory.restaurant.rawValue {
            ProximityManager.shared.refreshGeofences()
        }
    }

    /// Always run a web lookup for named restaurants. Web result wins when
    /// it exists; we keep the post-provided address separately so the UI
    /// can hint at a mismatch.
    private static func resolveAddress(
        extracted: RestaurantExtraction,
        authorHandle: String?
    ) async -> (address: String?, city: String?, source: AddressSource) {
        let postAddress = extracted.address
        let postCity = extracted.city

        let web = try? await AddressLookup.lookup(
            name: extracted.name,
            postAddress: postAddress,
            city: postCity,
            cuisine: extracted.cuisine,
            authorHandle: authorHandle
        )

        if let web, let webAddress = web.address, !webAddress.isEmpty {
            let source: AddressSource
            if let postAddress, !postAddress.isEmpty {
                source = normalize(webAddress) == normalize(postAddress) ? .web : .webCorrected
            } else {
                source = .web
            }
            return (webAddress, web.city ?? postCity, source)
        }

        // Web lookup failed or returned nothing — fall back to post.
        if let postAddress, !postAddress.isEmpty {
            return (postAddress, postCity, .post)
        }
        return (nil, postCity, .none)
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
