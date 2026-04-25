import SwiftUI
import SwiftData
import MapKit

/// Detail view for a saved item. Hero + stacked sections layout.
/// Tags and notes are inline-editable.
struct ItemDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: Item

    @State private var notesDraft: String = ""

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    chipRow
                    sections
                }
            }
            if hasCoordinates {
                VStack {
                    Spacer()
                    bottomActions
                        .padding(.horizontal, DSSpace.xxl)
                        .padding(.bottom, DSSpace.xxl)
                        .background(
                            LinearGradient(
                                colors: [Color.bgBase.opacity(0), Color.bgBase],
                                startPoint: .top, endPoint: .bottom
                            )
                            .ignoresSafeArea(.all, edges: .bottom)
                        )
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    item.isArchived.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: item.isArchived ? "tray.and.arrow.up" : "archivebox")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .onAppear { notesDraft = item.notes ?? "" }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            heroImage
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.bgBase],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                MetaLabel(
                    text: heroMetaText,
                    pulsing: isNearby,
                    tone: .accent
                )
                Text(item.title)
                    .font(.dsHeroTitle)
                    .tracking(DSTracking.heroTitle)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, DSSpace.xxl)
            .padding(.bottom, DSSpace.lg)
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        if let path = item.thumbnailPath,
           let url = ThumbnailStore.absoluteURL(for: path),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Color.bgRaised)
        }
    }

    // MARK: - Chip row

    private var chipRow: some View {
        HStack(spacing: 6) {
            Chip(label: (item.builtInCategory?.label ?? item.category).lowercased(), tone: .accent)
            ForEach(item.tags.prefix(4), id: \.self) { tag in
                Chip(label: tag.lowercased())
            }
        }
        .padding(.horizontal, DSSpace.xxl)
        .padding(.top, DSSpace.lg)
    }

    // MARK: - Sections

    @ViewBuilder
    private var sections: some View {
        if let r = item.restaurantDetails {
            section("Address") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(r.address ?? "—")
                        .font(.dsBody)
                        .foregroundStyle(Color.textPrimary)
                    if let hint = addressVerificationHint(for: r) {
                        Text(hint)
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                    if let lat = r.latitude, let lon = r.longitude {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                            latitudinalMeters: 500, longitudinalMeters: 500
                        ))) {
                            Marker(item.title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                .tint(Color.accent)
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.card))
                        .padding(.top, 4)
                    }
                }
            }
            if !r.notableDishes.isEmpty {
                section("Notable") {
                    VStack(spacing: 0) {
                        ForEach(r.notableDishes, id: \.self) { dish in
                            KeyValueRow(key: dish.lowercased().replacingOccurrences(of: " ", with: "-"), value: "★")
                        }
                    }
                }
            }
        }

        if let m = item.movieDetails {
            section("Movie") {
                VStack(spacing: 0) {
                    KeyValueRow(key: "year",      value: m.year.map(String.init))
                    KeyValueRow(key: "director",  value: m.director)
                    KeyValueRow(key: "genre",     value: m.genre)
                    KeyValueRow(key: "watch on",  value: m.whereToWatch)
                }
            }
        }

        if let s = item.showDetails {
            section("Show") {
                VStack(spacing: 0) {
                    KeyValueRow(key: "creator",   value: s.creator)
                    KeyValueRow(key: "network",   value: s.network)
                    KeyValueRow(key: "genre",     value: s.genre)
                    KeyValueRow(key: "watch on",  value: s.whereToWatch)
                }
            }
        }

        if let summary = item.summary, !summary.isEmpty {
            section("Summary") {
                Text(summary)
                    .font(.dsBody)
                    .foregroundStyle(Color.textPrimary)
            }
        }

        section("Tags") {
            TagEditor(tags: $item.tags)
                .onChange(of: item.tags) { _, _ in try? context.save() }
        }

        section("Notes") {
            TextField("Add a note…", text: $notesDraft, axis: .vertical)
                .font(.dsBody)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(3, reservesSpace: true)
                .onChange(of: notesDraft) { _, newValue in
                    item.notes = newValue.isEmpty ? nil : newValue
                    try? context.save()
                }
        }

        section("Source") {
            VStack(alignment: .leading, spacing: 6) {
                if let author = item.sourceAuthor {
                    KeyValueRow(key: "author", value: "@\(author)")
                }
                Link(destination: item.sourceURL) {
                    Text(item.sourceURL.absoluteString)
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.accent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }

        // Spacer at the bottom so the pinned CTA doesn't cover content.
        if hasCoordinates {
            Color.clear.frame(height: 90)
        } else {
            Color.clear.frame(height: 22)
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            Rectangle()
                .fill(Color.borderHairline)
                .frame(height: 0.5)
                .padding(.top, DSSpace.xl)
            VStack(alignment: .leading, spacing: DSSpace.sm) {
                SectionLabel(text: title)
                content()
            }
            .padding(.horizontal, DSSpace.xxl)
            .padding(.top, DSSpace.lg)
        }
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        HStack(spacing: DSSpace.md) {
            PrimaryButton(title: "Open in Maps", systemImage: "play.fill") {
                openInMaps()
            }
            GhostButton(title: "↗", systemImage: nil) {
                ShareActivity.share(url: item.sourceURL)
            }
            .frame(width: 56)
        }
    }

    // MARK: - Helpers

    private var hasCoordinates: Bool {
        item.restaurantDetails?.latitude != nil && item.restaurantDetails?.longitude != nil
    }

    private var isNearby: Bool {
        // Reserved for future live-distance hookup. Off in v1.
        false
    }

    private var heroMetaText: String {
        let category = (item.builtInCategory?.label ?? item.category).uppercased()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return "\(category) · \(formatter.string(from: item.dateAdded))"
    }

    private func addressVerificationHint(for r: RestaurantDetails) -> String? {
        switch r.addressSource {
        case .web:          return "verified · web search ✓"
        case .webCorrected: return "updated · web search ✓"
        case .post, .none:  return nil
        }
    }

    private func openInMaps() {
        guard let lat = item.restaurantDetails?.latitude,
              let lon = item.restaurantDetails?.longitude else { return }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        mapItem.name = item.title
        mapItem.openInMaps()
    }
}

/// Tiny wrapper for sharing a URL via UIActivityViewController.
enum ShareActivity {
    static func share(url: URL) {
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(av, animated: true)
    }
}
