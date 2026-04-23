import Foundation
import SwiftData

/// A saved reel. One row per item the user has captured.
///
/// `category` is a plain string (the canonical registry name — see
/// BuiltInCategory + CustomCategory). Restaurants, movies, and shows
/// have dedicated detail models; all other categories carry their
/// extracted facts in `summary`.
@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var sourceURL: URL
    var sourcePlatform: String      // "tiktok" | "instagram"
    var sourceAuthor: String?
    var caption: String?
    var thumbnailPath: String?
    var category: String
    var title: String
    var summary: String?
    var notes: String?
    var tags: [String]
    var dateAdded: Date
    var dateLastViewed: Date?
    var isArchived: Bool
    var aiConfidence: Double
    var needsReview: Bool

    @Relationship(deleteRule: .cascade, inverse: \RestaurantDetails.item)
    var restaurantDetails: RestaurantDetails?

    @Relationship(deleteRule: .cascade, inverse: \MovieDetails.item)
    var movieDetails: MovieDetails?

    @Relationship(deleteRule: .cascade, inverse: \ShowDetails.item)
    var showDetails: ShowDetails?

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        sourcePlatform: String,
        sourceAuthor: String? = nil,
        caption: String? = nil,
        thumbnailPath: String? = nil,
        category: String = BuiltInCategory.uncategorized.rawValue,
        title: String,
        summary: String? = nil,
        notes: String? = nil,
        tags: [String] = [],
        dateAdded: Date = .now,
        dateLastViewed: Date? = nil,
        isArchived: Bool = false,
        aiConfidence: Double = 0,
        needsReview: Bool = false
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourcePlatform = sourcePlatform
        self.sourceAuthor = sourceAuthor
        self.caption = caption
        self.thumbnailPath = thumbnailPath
        self.category = category
        self.title = title
        self.summary = summary
        self.notes = notes
        self.tags = tags
        self.dateAdded = dateAdded
        self.dateLastViewed = dateLastViewed
        self.isArchived = isArchived
        self.aiConfidence = aiConfidence
        self.needsReview = needsReview
    }
}

extension Item {
    var builtInCategory: BuiltInCategory? {
        BuiltInCategory(rawValue: category)
    }

    var isRestaurant: Bool { category == BuiltInCategory.restaurant.rawValue }
    var isMovie:      Bool { category == BuiltInCategory.movie.rawValue }
    var isShow:       Bool { category == BuiltInCategory.show.rawValue }
}
