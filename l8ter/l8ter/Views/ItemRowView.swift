import SwiftUI

/// A single row in the saved items list. 64pt thumbnail + meta label
/// + title + mono subline.
struct ItemRowView: View {
    let item: Item

    var body: some View {
        HStack(alignment: .center, spacing: DSSpace.lg) {
            thumbnail
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.thumbLarge))

            VStack(alignment: .leading, spacing: 3) {
                MetaLabel(
                    text: metaText,
                    pulsing: false,
                    tone: item.needsReview ? .accent : .neutral
                )
                Text(item.title)
                    .font(.dsRowTitle)
                    .tracking(DSTracking.rowTitle)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                if let subline {
                    Text(subline)
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.bgBase)
        .listRowSeparatorTint(Color.borderHairline)
    }

    private var metaText: String {
        let category = (item.builtInCategory?.label ?? item.category).uppercased()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return "\(category) · \(formatter.string(from: item.dateAdded))"
    }

    private var subline: String? {
        if let r = item.restaurantDetails {
            let parts = [r.cuisine, r.address?.split(separator: ",").first.map(String.init)]
                .compactMap { $0 }
                .map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        }
        if let m = item.movieDetails {
            let parts = [m.director, m.year.map(String.init)]
                .compactMap { $0 }
                .map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        }
        if let s = item.showDetails {
            let parts = [s.creator, s.network]
                .compactMap { $0 }
                .map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
        }
        if let summary = item.summary, !summary.isEmpty {
            return summary
        }
        if let author = item.sourceAuthor {
            return "@\(author)"
        }
        return nil
    }

    @ViewBuilder
    private var thumbnail: some View {
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
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(Color.textDisabled)
                )
        }
    }
}
