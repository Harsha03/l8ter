import SwiftUI
import SwiftData
import MapKit

/// Detail view for a saved item. Read-only except for tags and notes,
/// which can be edited inline.
struct ItemDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: Item

    @State private var notesDraft: String = ""

    var body: some View {
        Form {
            if let path = item.thumbnailPath,
               let url = ThumbnailStore.absoluteURL(for: path),
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                }
            }

            Section("Summary") {
                labeled("title", item.title)
                labeled("category", item.builtInCategory?.label ?? item.category.capitalized)
                labeled("confidence", String(format: "%.2f", item.aiConfidence))
                if item.needsReview {
                    Text("Flagged for review")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if let summary = item.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.callout)
                        .padding(.vertical, 4)
                }
            }

            if let m = item.movieDetails {
                Section("Movie") {
                    labeled("year", m.year.map(String.init))
                    labeled("director", m.director)
                    labeled("genre", m.genre)
                    labeled("where to watch", m.whereToWatch)
                }
            }

            if let s = item.showDetails {
                Section("Show") {
                    labeled("creator", s.creator)
                    labeled("network", s.network)
                    labeled("genre", s.genre)
                    labeled("where to watch", s.whereToWatch)
                }
            }

            if let details = item.restaurantDetails {
                Section("Restaurant") {
                    labeled("address", details.address)
                    addressSourceHint(details)
                    labeled("cuisine", details.cuisine)
                    if !details.notableDishes.isEmpty {
                        labeled("dishes", details.notableDishes.joined(separator: ", "))
                    }
                    if let lat = details.latitude, let lon = details.longitude {
                        labeled("coords", String(format: "%.5f, %.5f", lat, lon))
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                            latitudinalMeters: 500,
                            longitudinalMeters: 500
                        ))) {
                            Marker(item.title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                .tint(.red)
                        }
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button {
                            openInMaps(lat: lat, lon: lon)
                        } label: {
                            Label("Open in Maps", systemImage: "map")
                        }
                    } else {
                        Text("Not geocoded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Tags") {
                TagEditor(tags: $item.tags)
                    .onChange(of: item.tags) { _, _ in try? context.save() }
            }

            Section("Notes") {
                TextField("Add a note…", text: $notesDraft, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .onAppear { notesDraft = item.notes ?? "" }
                    .onChange(of: notesDraft) { _, newValue in
                        item.notes = newValue.isEmpty ? nil : newValue
                        try? context.save()
                    }
            }

            Section("Source") {
                labeled("platform", item.sourcePlatform)
                if let author = item.sourceAuthor {
                    labeled("author", "@\(author)")
                }
                Link(item.sourceURL.absoluteString, destination: item.sourceURL)
                    .font(.caption)
            }

            if let caption = item.caption, !caption.isEmpty {
                Section("Caption") {
                    Text(caption)
                        .font(.caption)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    item.isArchived.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: item.isArchived ? "tray.and.arrow.up" : "archivebox")
                }
            }
        }
    }

    @ViewBuilder
    private func addressSourceHint(_ details: RestaurantDetails) -> some View {
        switch details.addressSource {
        case .web:
            Label("Verified via web search", systemImage: "checkmark.seal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .webCorrected:
            VStack(alignment: .leading, spacing: 2) {
                Label("Updated from web search", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let original = details.postProvidedAddress {
                    Text("Post said: \(original)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        case .post, .none:
            EmptyView()
        }
    }

    private func openInMaps(lat: Double, lon: Double) {
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        mapItem.name = item.title
        mapItem.openInMaps()
    }

    @ViewBuilder
    private func labeled(_ key: String, _ value: String?) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "—")
                .font(.caption)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}
