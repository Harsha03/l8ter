import SwiftUI

/// Inline tag editor. Shows existing tags as chips with a delete tap;
/// a compact text field appends new ones on return or comma.
struct TagEditor: View {
    @Binding var tags: [String]

    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpace.sm) {
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            remove(tag)
                        } label: {
                            HStack(spacing: 4) {
                                Text(tag.lowercased())
                                    .font(.dsMetaSmall)
                                    .foregroundStyle(Color.textSecondary)
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(Color.textTertiary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.chip)
                                    .strokeBorder(Color.borderQuiet, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            TextField("add tag", text: $draft)
                .font(.dsMetaSmall)
                .foregroundStyle(Color.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(commitDraft)
                .onChange(of: draft) { _, newValue in
                    if newValue.hasSuffix(",") {
                        draft = String(newValue.dropLast())
                        commitDraft()
                    }
                }
        }
    }

    private func commitDraft() {
        let tag = draft.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !tags.contains(tag) else {
            draft = ""
            return
        }
        tags.append(tag)
        draft = ""
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

/// Simple wrap-flow layout for tag chips. iOS 16+.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = layout(in: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.maxY } ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = layout(in: bounds.width, subviews: subviews)
        for row in rows {
            for placed in row.items {
                placed.subview.place(
                    at: CGPoint(x: bounds.minX + placed.x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(width: placed.size.width, height: placed.size.height)
                )
            }
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row(y: 0)]
        var cursorX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if cursorX + size.width > width, !rows[rows.count - 1].items.isEmpty {
                let last = rows[rows.count - 1]
                rows.append(Row(y: last.maxY + spacing))
                cursorX = 0
            }
            rows[rows.count - 1].items.append(PlacedItem(subview: subview, x: cursorX, size: size))
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
            cursorX += size.width + spacing
        }
        return rows
    }

    struct Row {
        var y: CGFloat
        var height: CGFloat = 0
        var items: [PlacedItem] = []
        var maxY: CGFloat { y + height }
    }

    struct PlacedItem {
        let subview: LayoutSubview
        let x: CGFloat
        let size: CGSize
    }
}
