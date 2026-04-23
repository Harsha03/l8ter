import SwiftUI

/// A single row in the saved items list. Thumbnail + title + category + author.
struct ItemRowView: View {
    let item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(item.builtInCategory?.label ?? item.category.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundStyle(categoryColor)
                        .clipShape(Capsule())
                    if item.needsReview {
                        Text("review")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                    if item.restaurantDetails?.addressSource == .webCorrected {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let author = item.sourceAuthor {
                    Text("@\(author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
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
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                )
        }
    }

    private var categoryColor: Color {
        switch item.builtInCategory {
        case .restaurant:   return .red
        case .movie:        return .blue
        case .show:         return .purple
        case .activity:     return .green
        case .recipe:       return .orange
        case .place:        return .teal
        case .book:         return .indigo
        case .product:      return .pink
        case .uncategorized, .none: return .gray
        }
    }
}
