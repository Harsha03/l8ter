// l8ter/l8ter/Views/DesignSystem/Components/ConfidenceBar.swift
import SwiftUI

/// Tiny 3pt-tall bar with purple fill + glow. Shows extraction
/// confidence in the review queue and the post-save state.
struct ConfidenceBar: View {
    /// 0.0 ... 1.0
    let value: Double
    var width: CGFloat = 60

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.bgRaised)
            Capsule()
                .fill(Color.accent)
                .shadow(color: Color.accent.opacity(0.6), radius: 4)
                .frame(width: width * CGFloat(max(0, min(1, value))))
        }
        .frame(width: width, height: 3)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        ConfidenceBar(value: 0.92)
        ConfidenceBar(value: 0.48)
        ConfidenceBar(value: 0.35)
    }
    .padding(40)
    .background(Color.bgBase)
}
