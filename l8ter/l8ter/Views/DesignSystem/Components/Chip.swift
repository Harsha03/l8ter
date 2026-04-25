// l8ter/l8ter/Views/DesignSystem/Components/Chip.swift
import SwiftUI

/// Hairline-bordered pill. Two tones: neutral (default) and accent
/// (purple-tinted). Used for tags, filter pills, category labels.
struct Chip: View {
    let label: String
    var tone: Tone = .neutral

    enum Tone {
        case neutral
        case accent
    }

    var body: some View {
        Text(label)
            .font(.dsMetaSmall)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.chip)
                    .strokeBorder(border, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.chip))
    }

    private var foreground: Color {
        switch tone {
        case .neutral: return .textSecondary
        case .accent:  return .accentBright
        }
    }

    private var background: Color {
        switch tone {
        case .neutral: return .clear
        case .accent:  return .accentTint
        }
    }

    private var border: Color {
        switch tone {
        case .neutral: return .borderQuiet
        case .accent:  return .accentBorderSoft
        }
    }
}

#Preview {
    HStack(spacing: 6) {
        Chip(label: "sicilian", tone: .accent)
        Chip(label: "slice")
        Chip(label: "bklyn")
    }
    .padding(40)
    .background(Color.bgBase)
}
