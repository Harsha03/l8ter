import SwiftUI
import SwiftData
import MapKit

/// Map of all geocoded restaurants. Glyph pins (mono-cap labels) +
/// floating header chip + bottom selection card.
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
            ZStack(alignment: .top) {
                if geocodedItems.isEmpty {
                    Color.bgBase.ignoresSafeArea()
                    ContentUnavailableView(
                        "No restaurants yet",
                        systemImage: "mappin.slash",
                        description: Text("Save a restaurant reel with an address and it shows up here.")
                    )
                } else {
                    mapView
                    floatingHeader
                        .padding(.horizontal, DSSpace.xl)
                        .padding(.top, DSSpace.lg)
                }
            }
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var mapView: some View {
        Map(position: $cameraPosition, selection: $selectedItemID) {
            ForEach(geocodedItems) { item in
                if let coord = coordinate(for: item) {
                    Annotation(item.title, coordinate: coord) {
                        pinView(for: item)
                    }
                    .tag(item.id)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .preferredColorScheme(.dark)
        .safeAreaInset(edge: .bottom) {
            if let selected {
                selectionCard(for: selected)
                    .padding(.horizontal, DSSpace.xxl)
                    .padding(.bottom, DSSpace.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: selectedItemID)
    }

    @ViewBuilder
    private func pinView(for item: Item) -> some View {
        let isSelected = item.id == selectedItemID
        VStack(spacing: 3) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.accentTintStrong)
                        .frame(width: 34, height: 34)
                }
                Circle()
                    .fill(isSelected ? Color.accent : Color.textPrimary)
                    .frame(width: isSelected ? 16 : 10, height: isSelected ? 16 : 10)
                    .overlay(
                        Circle().strokeBorder(Color.bgBase, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color.accent.opacity(0.6) : .clear, radius: 8)
            }
            Text(item.title.uppercased().prefix(12))
                .font(.dsMetaTiny)
                .tracking(DSTracking.metaTiny)
                .foregroundStyle(isSelected ? Color.accent : Color.textSecondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.bgBase.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    private var floatingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                MetaLabel(text: "NEAR YOU · \(geocodedItems.count) SAVED", pulsing: true, tone: .accent)
                Text("Map")
                    .font(.dsScreenTitle)
                    .tracking(DSTracking.screenTitle)
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            Button {
                cameraPosition = .automatic
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 11, weight: .semibold))
                    Text("RECENTER")
                        .font(.dsMetaCaps)
                        .tracking(DSTracking.metaCaps)
                }
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.bgBase.opacity(0.85))
                .overlay(
                    Capsule().strokeBorder(Color.borderQuiet, lineWidth: 0.5)
                )
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func selectionCard(for item: Item) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            MetaLabel(text: metaText(for: item), pulsing: false, tone: .accent)
            Text(item.title)
                .font(.dsCardTitle)
                .tracking(DSTracking.cardTitle)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            if let address = item.restaurantDetails?.address {
                Text(address.lowercased())
                    .font(.dsMetaSmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            HStack(spacing: DSSpace.md) {
                PrimaryButton(title: "Open in Maps", systemImage: "play.fill") {
                    openInMaps(item: item)
                }
                NavigationLink {
                    ItemDetailView(item: item)
                } label: {
                    Text("Details")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(Color.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DSRadius.button)
                                .strokeBorder(Color.borderQuiet, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(DSSpace.xl)
        .background(Color.bgBase)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.card)
                .strokeBorder(Color.borderHairline, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.card))
    }

    // MARK: - Data helpers

    private var geocodedItems: [Item] {
        items.filter { coordinate(for: $0) != nil && $0.isRestaurant }
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

    private func metaText(for item: Item) -> String {
        let category = (item.builtInCategory?.label ?? item.category).uppercased()
        return "\(category) · SAVED"
    }

    private func openInMaps(item: Item) {
        guard let coord = coordinate(for: item) else { return }
        let placemark = MKPlacemark(coordinate: coord)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = item.title
        mapItem.openInMaps()
    }
}

#Preview {
    RestaurantsMapView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
