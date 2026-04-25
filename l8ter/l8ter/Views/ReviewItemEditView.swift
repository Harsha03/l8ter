import SwiftUI
import SwiftData

/// Editor for a single review-queue item. Lets the user fix the title,
/// category, and category-specific fields, then clear `needsReview`.
struct ReviewItemEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @Bindable var item: Item

    @State private var title: String = ""
    @State private var category: String = BuiltInCategory.uncategorized.rawValue
    @State private var summary: String = ""

    // Restaurant
    @State private var restaurantAddress: String = ""
    @State private var restaurantCuisine: String = ""
    @State private var restaurantDishes: String = ""

    // Movie
    @State private var movieYear: String = ""
    @State private var movieDirector: String = ""
    @State private var movieGenre: String = ""
    @State private var movieWhereToWatch: String = ""

    // Show
    @State private var showCreator: String = ""
    @State private var showNetwork: String = ""
    @State private var showGenre: String = ""
    @State private var showWhereToWatch: String = ""

    @State private var isRerunning = false
    @State private var rerunError: String?

    private var options: [CategoryOption] {
        CategoryRegistry.options(customCategories: customCategories)
    }

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(.dsBody)
                    Picker("Category", selection: $category) {
                        ForEach(options) { opt in
                            Text(opt.label).tag(opt.name)
                        }
                    }
                } header: {
                    SectionLabel(text: "Basics")
                }

                if let builtIn = BuiltInCategory(rawValue: category) {
                    switch builtIn {
                    case .restaurant:
                        Section {
                            TextField("Address", text: $restaurantAddress, axis: .vertical)
                            TextField("Cuisine", text: $restaurantCuisine)
                            TextField("Notable dishes (comma-separated)", text: $restaurantDishes, axis: .vertical)
                        } header: { SectionLabel(text: "Restaurant") }
                    case .movie:
                        Section {
                            TextField("Year", text: $movieYear)
                                .keyboardType(.numberPad)
                            TextField("Director", text: $movieDirector)
                            TextField("Genre", text: $movieGenre)
                            TextField("Where to watch", text: $movieWhereToWatch)
                        } header: { SectionLabel(text: "Movie") }
                    case .show:
                        Section {
                            TextField("Creator", text: $showCreator)
                            TextField("Network", text: $showNetwork)
                            TextField("Genre", text: $showGenre)
                            TextField("Where to watch", text: $showWhereToWatch)
                        } header: { SectionLabel(text: "Show") }
                    case .activity, .recipe, .place, .book, .product, .uncategorized:
                        Section {
                            TextField("Short description", text: $summary, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                        } header: { SectionLabel(text: "Summary") }
                    }
                } else {
                    Section {
                        TextField("Short description", text: $summary, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    } header: { SectionLabel(text: "Summary") }
                }

                Section {
                    Button {
                        Task { await rerunExtraction() }
                    } label: {
                        if isRerunning {
                            HStack { ProgressView().tint(Color.accent); Text("Re-running…") }
                        } else {
                            Label("Re-run extraction", systemImage: "arrow.clockwise")
                                .foregroundStyle(Color.accent)
                        }
                    }
                    .disabled(isRerunning)

                    if let rerunError {
                        Text(rerunError)
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgBase)
        }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    save(clearingReview: true)
                    dismiss()
                }
                .foregroundStyle(Color.accent)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        title = item.title
        category = item.category
        summary = item.summary ?? ""

        if let r = item.restaurantDetails {
            restaurantAddress = r.address ?? ""
            restaurantCuisine = r.cuisine ?? ""
            restaurantDishes = r.notableDishes.joined(separator: ", ")
        }
        if let m = item.movieDetails {
            movieYear = m.year.map(String.init) ?? ""
            movieDirector = m.director ?? ""
            movieGenre = m.genre ?? ""
            movieWhereToWatch = m.whereToWatch ?? ""
        }
        if let s = item.showDetails {
            showCreator = s.creator ?? ""
            showNetwork = s.network ?? ""
            showGenre = s.genre ?? ""
            showWhereToWatch = s.whereToWatch ?? ""
        }
    }

    private func save(clearingReview: Bool) {
        item.title = title.isEmpty ? item.title : title

        let previousCategory = item.category
        item.category = category

        if previousCategory != category {
            detachDetails(keep: category)
        }

        item.summary = nilIfEmpty(summary)

        switch BuiltInCategory(rawValue: category) {
        case .restaurant:
            let details = item.restaurantDetails ?? RestaurantDetails()
            details.address = nilIfEmpty(restaurantAddress)
            details.cuisine = nilIfEmpty(restaurantCuisine)
            details.notableDishes = restaurantDishes
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if item.restaurantDetails == nil {
                context.insert(details)
                item.restaurantDetails = details
            }
        case .movie:
            let details = item.movieDetails ?? MovieDetails()
            details.year = Int(movieYear)
            details.director = nilIfEmpty(movieDirector)
            details.genre = nilIfEmpty(movieGenre)
            details.whereToWatch = nilIfEmpty(movieWhereToWatch)
            if item.movieDetails == nil {
                context.insert(details)
                item.movieDetails = details
            }
        case .show:
            let details = item.showDetails ?? ShowDetails()
            details.creator = nilIfEmpty(showCreator)
            details.network = nilIfEmpty(showNetwork)
            details.genre = nilIfEmpty(showGenre)
            details.whereToWatch = nilIfEmpty(showWhereToWatch)
            if item.showDetails == nil {
                context.insert(details)
                item.showDetails = details
            }
        default:
            break
        }

        if clearingReview {
            item.needsReview = false
        }
        try? context.save()
    }

    /// Drop detail models that don't match the selected category.
    private func detachDetails(keep category: String) {
        if category != BuiltInCategory.restaurant.rawValue, let r = item.restaurantDetails {
            context.delete(r)
            item.restaurantDetails = nil
        }
        if category != BuiltInCategory.movie.rawValue, let m = item.movieDetails {
            context.delete(m)
            item.movieDetails = nil
        }
        if category != BuiltInCategory.show.rawValue, let s = item.showDetails {
            context.delete(s)
            item.showDetails = nil
        }
    }

    private func nilIfEmpty(_ s: String) -> String? {
        s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : s
    }

    private func rerunExtraction() async {
        isRerunning = true
        rerunError = nil
        defer { isRerunning = false }

        do {
            let fetch = try await TikTokOEmbed.fetch(reelURL: item.sourceURL.absoluteString)
            let extraction = try await ClaudeExtractor.extract(
                oEmbed: fetch.response,
                sourceURL: item.sourceURL.absoluteString,
                platform: item.sourcePlatform,
                categoryOptions: options
            )

            title = extraction.title
            category = extraction.category
            summary = extraction.summary ?? summary
            if let r = extraction.restaurant {
                restaurantAddress = r.address ?? ""
                restaurantCuisine = r.cuisine ?? ""
                restaurantDishes = r.notableDishes.joined(separator: ", ")
            }
            if let m = extraction.movie {
                movieYear = m.year.map(String.init) ?? ""
                movieDirector = m.director ?? ""
                movieGenre = m.genre ?? ""
                movieWhereToWatch = m.whereToWatch ?? ""
            }
            if let s = extraction.show {
                showCreator = s.creator ?? ""
                showNetwork = s.network ?? ""
                showGenre = s.genre ?? ""
                showWhereToWatch = s.whereToWatch ?? ""
            }
        } catch {
            rerunError = "\(error)"
        }
    }
}
