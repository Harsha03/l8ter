// l8ter/l8ter/Views/DesignSystem/Components/SectionLabel.swift
import SwiftUI

/// Small mono-caps eyebrow used as a section header above row groups.
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.dsMetaCaps)
            .tracking(DSTracking.metaCaps)
            .foregroundStyle(Color.textTertiary)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SectionLabel(text: "Address")
        SectionLabel(text: "Notable")
        SectionLabel(text: "Source")
    }
    .padding(40)
    .background(Color.bgBase)
}
