// l8ter/l8ter/Views/DesignSystem/Components/KeyValueRow.swift
import SwiftUI

/// Mono key on the left in textSecondary, value on the right in
/// textPrimary. Used in Settings, Detail "Notable" section, etc.
struct KeyValueRow: View {
    let key: String
    let value: String?
    var valueTone: ValueTone = .primary

    enum ValueTone {
        case primary
        case accent
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key)
                .font(.dsMetaSmall)
                .foregroundStyle(Color.textSecondary)
            Spacer(minLength: 8)
            Text(value ?? "—")
                .font(.dsBody)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .padding(.vertical, 6)
    }

    private var valueColor: Color {
        switch valueTone {
        case .primary: return .textPrimary
        case .accent:  return .accent
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        KeyValueRow(key: "cuisine", value: "Sicilian")
        KeyValueRow(key: "address", value: "8616 Ave X, Brooklyn")
        KeyValueRow(key: "verified", value: "via web search", valueTone: .accent)
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 20)
    .background(Color.bgBase)
}
