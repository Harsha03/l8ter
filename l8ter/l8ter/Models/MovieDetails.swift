import Foundation
import SwiftData

/// Movie-specific fields. Linked from Item.movieDetails.
@Model
final class MovieDetails {
    var year: Int?
    var director: String?
    var genre: String?
    var whereToWatch: String?

    var item: Item?

    init(
        year: Int? = nil,
        director: String? = nil,
        genre: String? = nil,
        whereToWatch: String? = nil
    ) {
        self.year = year
        self.director = director
        self.genre = genre
        self.whereToWatch = whereToWatch
    }
}
