import SwiftUI
import SwiftData
import MapKit

/// Map of all geocoded restaurants. Taps on a marker select it and
/// reveal an "Open in Maps" action that hands off to Apple Maps.
struct RestaurantsMapView: View {
    @Query(
        filter: #Predicate<Item> { !$0.isArchived },
        sort: [SortDescriptor(\Item.dateAdded, order: .reverse)]
    )
    private var items: [Item]

    @State private var selectedItemID: UUID?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if geocodedItems.isEmpty {
                    ContentUnavailableView(
                        "No restaurants yet",
                        systemImage: "mappin.slash",
                        description: Text("Save a restaurant reel with an address and it shows up here.")
                    )
                } else {
                    Map(position: $cameraPosition, selection: $selectedItemID) {
                        ForEach(geocodedItems) { item in
                            if let coord = coordinate(for: item) {
                                Marker(item.title, coordinate: coord)
                                    .tint(.red)
                                    .tag(item.id)
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        if let selected {
                            selectionCard(for: selected)
                                .padding()
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.default, value: selectedItemID)
                }
            }
            .navigationTitle("Map")
        }
    }

    private var geocodedItems: [Item] {
        items.filter { coordinate(for: $0) != nil }
    }

    private var selected: Item? {
        guard let id = selectedItemID else { return nil }
        return items.first { $0.id == id }
    }

    private func coordinate(for item: Item) -> CLLocationCoordinate2D? {
        guard let lat = item.restaurantDetails?.latitude,
              let lon = item.restaurantDetails?.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    @ViewBuilder
    private func selectionCard(for item: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title).font(.headline)
            if let address = item.restaurantDetails?.address {
                Text(address).font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                NavigationLink("Details") {
                    ItemDetailView(item: item)
                }
                .buttonStyle(.bordered)
                Spacer()
                Button {
                    openInMaps(item: item)
                } label: {
                    Label("Open in Maps", systemImage: "map")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func openInMaps(item: Item) {
        guard let coord = coordinate(for: item) else { return }
        let placemark = MKPlacemark(coordinate: coord)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = item.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapTypeKey: NSNumber(value: MKMapType.standard.rawValue)
        ])
    }
}

#Preview {
    RestaurantsMapView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
