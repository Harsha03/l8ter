import SwiftUI
import SwiftData

/// Items the AI flagged for human review: low confidence or
/// uncategorized. Tap a row to open the editor.
struct ReviewQueueView: View {
    @Query(
        filter: #Predicate<Item> { !$0.isArchived && $0.needsReview },
        sort: [SortDescriptor(\Item.dateAdded, order: .reverse)]
    )
    private var items: [Item]

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing to review",
                        systemImage: "checkmark.seal",
                        description: Text("Items land here when the AI isn't sure. You're all caught up.")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                ReviewItemEditView(item: item)
                            } label: {
                                ItemRowView(item: item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Review")
        }
    }
}

#Preview {
    ReviewQueueView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
