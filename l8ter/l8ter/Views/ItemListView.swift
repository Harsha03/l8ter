import SwiftUI
import SwiftData

/// Main "Saved" view. Lists all non-archived items, newest first.
/// Supports search, category filter, archive/unarchive, delete.
struct ItemListView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\Item.dateAdded, order: .reverse)])
    private var allItems: [Item]

    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @State private var filterName: String = "all"
    @State private var searchText: String = ""
    @State private var showArchived: Bool = false

    private var options: [CategoryOption] {
        CategoryRegistry.options(customCategories: customCategories)
    }

    var body: some View {
        NavigationStack {
            Group {
                if allItems.isEmpty {
                    ContentUnavailableView(
                        "Nothing saved yet",
                        systemImage: "tray",
                        description: Text("Paste a TikTok URL on the Add tab to save your first reel.")
                    )
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filtered) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                ItemRowView(item: item)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    toggleArchive(item)
                                } label: {
                                    Label(
                                        item.isArchived ? "Unarchive" : "Archive",
                                        systemImage: item.isArchived ? "tray.and.arrow.up" : "archivebox"
                                    )
                                }
                                .tint(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle(showArchived ? "Archived" : "Saved")
            .searchable(text: $searchText, prompt: "Search title, caption, notes, tags")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Category", selection: $filterName) {
                            Text("All").tag("all")
                            ForEach(options) { opt in
                                Text(opt.label).tag(opt.name)
                            }
                        }
                        Divider()
                        Toggle("Show archived", isOn: $showArchived)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    private var filtered: [Item] {
        let archivedScoped = allItems.filter { $0.isArchived == showArchived }
        let categoryScoped = filterName == "all"
            ? archivedScoped
            : archivedScoped.filter { $0.category == filterName }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return categoryScoped }
        return categoryScoped.filter { matches($0, query: query) }
    }

    private func matches(_ item: Item, query: String) -> Bool {
        if item.title.lowercased().contains(query) { return true }
        if let caption = item.caption, caption.lowercased().contains(query) { return true }
        if let summary = item.summary, summary.lowercased().contains(query) { return true }
        if let notes = item.notes, notes.lowercased().contains(query) { return true }
        if item.tags.contains(where: { $0.lowercased().contains(query) }) { return true }
        if let author = item.sourceAuthor, author.lowercased().contains(query) { return true }
        if let r = item.restaurantDetails {
            if r.cuisine?.lowercased().contains(query) == true { return true }
            if r.address?.lowercased().contains(query) == true { return true }
            if r.notableDishes.contains(where: { $0.lowercased().contains(query) }) { return true }
        }
        if let m = item.movieDetails {
            if m.director?.lowercased().contains(query) == true { return true }
            if m.genre?.lowercased().contains(query) == true { return true }
        }
        if let s = item.showDetails {
            if s.creator?.lowercased().contains(query) == true { return true }
            if s.network?.lowercased().contains(query) == true { return true }
            if s.genre?.lowercased().contains(query) == true { return true }
        }
        return false
    }

    private func delete(_ item: Item) {
        context.delete(item)
        try? context.save()
    }

    private func toggleArchive(_ item: Item) {
        item.isArchived.toggle()
        try? context.save()
    }
}

#Preview {
    ItemListView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
