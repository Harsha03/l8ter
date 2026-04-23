import Foundation
import SwiftData

/// Show-specific fields. Linked from Item.showDetails.
@Model
final class ShowDetails {
    var creator: String?
    var network: String?
    var genre: String?
    var whereToWatch: String?

    var item: Item?

    init(
        creator: String? = nil,
        network: String? = nil,
        genre: String? = nil,
        whereToWatch: String? = nil
    ) {
        self.creator = creator
        self.network = network
        self.genre = genre
        self.whereToWatch = whereToWatch
    }
}
