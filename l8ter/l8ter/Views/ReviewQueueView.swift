import SwiftUI
import SwiftData

/// Items the AI flagged for human review: low confidence or
/// uncategorized. Rows show a compact 48pt thumbnail + meta + title +
/// confidence bar.
struct ReviewQueueView: View {
    @Query(
        filter: #Predicate<Item> { !$0.isArchived && $0.needsReview },
        sort: [SortDescriptor(\Item.dateAdded, order: .reverse)]
    )
    private var items: [Item]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgBase.ignoresSafeArea()
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing to review",
                        systemImage: "checkmark.seal",
                        description: Text("Items land here when the AI isn't sure. You're all caught up.")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        helper
                        Divider().background(Color.borderHairline)
                        list
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel(text: "Needs cleanup")
                Text("Review")
                    .font(.dsScreenTitle)
                    .tracking(DSTracking.screenTitle)
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            Text("\(items.count) ITEMS")
                .font(.dsMetaCaps)
                .tracking(DSTracking.metaCaps)
                .foregroundStyle(Color.accent)
        }
        .padding(.horizontal, DSSpace.xxl)
        .padding(.top, DSSpace.xs)
    }

    private var helper: some View {
        Text("Items where Claude wasn't sure. Edit and clear, or skip.")
            .font(.dsMetaSmall)
            .foregroundStyle(Color.textTertiary)
            .padding(.horizontal, DSSpace.xxl)
            .padding(.top, DSSpace.sm)
            .padding(.bottom, DSSpace.lg)
    }

    private var list: some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    ReviewItemEditView(item: item)
                } label: {
                    row(for: item)
                }
                .listRowBackground(Color.bgBase)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.bgBase)
    }

    @ViewBuilder
    private func row(for item: Item) -> some View {
        HStack(alignment: .center, spacing: DSSpace.lg) {
            thumbnail(for: item)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.thumb))

            VStack(alignment: .leading, spacing: 4) {
                MetaLabel(
                    text: rowMeta(for: item),
                    tone: item.category == BuiltInCategory.uncategorized.rawValue ? .accent : .neutral
                )
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.dsRowTitle)
                    .tracking(DSTracking.rowTitle)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    ConfidenceBar(value: item.aiConfidence, width: 60)
                    Text(String(format: "%.2f", item.aiConfidence))
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.accent)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func rowMeta(for item: Item) -> String {
        let category = (item.builtInCategory?.label ?? item.category).uppercased()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return "\(category) · \(formatter.string(from: item.dateAdded))"
    }

    @ViewBuilder
    private func thumbnail(for item: Item) -> some View {
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

#Preview {
    ReviewQueueView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
