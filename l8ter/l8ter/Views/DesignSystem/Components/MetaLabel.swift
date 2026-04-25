// l8ter/l8ter/Views/DesignSystem/Components/MetaLabel.swift
import SwiftUI

/// Mono-caps label used everywhere for category + state lines.
/// e.g. "EAT · 0.4 MI", "MOVIE · 04.21".
struct MetaLabel: View {
    let text: String
    var pulsing: Bool = false
    var tone: Tone = .neutral

    enum Tone {
        case neutral
        case accent
    }

    var body: some View {
        HStack(spacing: 5) {
            if pulsing {
                Pulse(animated: true)
            }
            Text(text.uppercased())
                .font(.dsMetaCaps)
                .tracking(DSTracking.metaCaps)
                .foregroundStyle(tone == .accent ? Color.accent : Color.textTertiary)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        MetaLabel(text: "EAT · 04.22")
        MetaLabel(text: "EAT · 0.4 MI", pulsing: true, tone: .accent)
        MetaLabel(text: "03 · SAVED", tone: .accent)
    }
    .padding(40)
    .background(Color.bgBase)
}
