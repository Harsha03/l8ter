import Foundation
import SwiftData

/// Built-in categories shipped with the app. Values are the canonical
/// category names used everywhere (Item.category, Claude tool schema,
/// UI filters). Descriptions are fed into the Claude user prompt so
/// the model knows when to pick each category.
///
/// Restaurants, movies, and shows have their own structured detail
/// models. Everything else uses the freeform `summary` string on Item.
enum BuiltInCategory: String, CaseIterable {
    case restaurant
    case movie
    case show
    case activity
    case recipe
    case place
    case book
    case product
    case uncategorized

    var label: String {
        switch self {
        case .restaurant:   return "Restaurant"
        case .movie:        return "Movie"
        case .show:         return "Show"
        case .activity:     return "Activity"
        case .recipe:       return "Recipe"
        case .place:        return "Place"
        case .book:         return "Book"
        case .product:      return "Product"
        case .uncategorized: return "Uncategorized"
        }
    }

    /// Description fed to Claude as part of the category registry in
    /// the user prompt. Should state what qualifies and what does not.
    var defaultDescription: String {
        switch self {
        case .restaurant:
            return "A specific, nameable restaurant or venue the user might want to visit. Recipes and general food content without a named venue are NOT restaurants."
        case .movie:
            return "A specific theatrical or streaming film being recommended, reviewed, or discussed."
        case .show:
            return "A specific TV series or streaming show being recommended, reviewed, or discussed."
        case .activity:
            return "A specific thing to do — hike, event, class, experience, sport, hobby. Not a place by itself; the focus is the action."
        case .recipe:
            return "A cooking or baking recipe: ingredients, technique, or a dish to make at home. Not a restaurant visit."
        case .place:
            return "A non-restaurant place worth visiting — park, museum, neighborhood, shop, landmark, bar/cafe where the focus is the venue, not a meal."
        case .book:
            return "A specific book being recommended or discussed."
        case .product:
            return "A specific physical product being reviewed or recommended (gear, gadgets, clothing, etc.). Not services and not generic categories of products."
        case .uncategorized:
            return "Anything else, or when you are less than 50% confident the post fits any other category."
        }
    }

    /// Categories that have structured detail models. Everything else
    /// uses the freeform summary field only.
    var hasStructuredDetails: Bool {
        switch self {
        case .restaurant, .movie, .show: return true
        default: return false
        }
    }
}

/// User-defined category. `name` is the canonical identifier (kept
/// unique and lowercased). `prompt` is the description the user writes
/// to teach Claude when to pick it.
@Model
final class CustomCategory {
    @Attribute(.unique) var name: String
    var prompt: String
    var createdAt: Date

    init(name: String, prompt: String, createdAt: Date = .now) {
        self.name = name
        self.prompt = prompt
        self.createdAt = createdAt
    }
}

/// Combined list of available categories (built-in + custom), used to
/// build the Claude prompt and UI pickers.
struct CategoryOption: Identifiable, Hashable {
    let name: String        // canonical identifier stored on Item.category
    let label: String       // display label
    let description: String
    let isBuiltIn: Bool

    var id: String { name }
}

enum CategoryRegistry {
    /// Build the list of categories currently available. Used by both
    /// the Claude extractor and the UI pickers.
    static func options(customCategories: [CustomCategory]) -> [CategoryOption] {
        var options = BuiltInCategory.allCases.map { b in
            CategoryOption(
                name: b.rawValue,
                label: b.label,
                description: b.defaultDescription,
                isBuiltIn: true
            )
        }
        let existing = Set(options.map(\.name))
        for c in customCategories where !existing.contains(c.name) {
            options.append(
                CategoryOption(
                    name: c.name,
                    label: c.name.capitalized,
                    description: c.prompt,
                    isBuiltIn: false
                )
            )
        }
        return options
    }

    /// Normalize a user-typed category name: lowercased, trimmed,
    /// inner whitespace collapsed to single spaces. Used as the stored
    /// identifier and for uniqueness checks.
    static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let collapsed = trimmed.replacingOccurrences(
            of: "\\s+", with: " ", options: .regularExpression
        )
        return collapsed
    }
}
