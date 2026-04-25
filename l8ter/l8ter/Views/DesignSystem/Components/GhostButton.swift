import SwiftUI

/// Hairline-bordered button. Light text on transparent background.
struct GhostButton: View {
    let title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
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
}

#Preview {
    HStack(spacing: 12) {
        GhostButton(title: "Add another") {}
        PrimaryButton(title: "View →") {}
    }
    .padding(40)
    .background(Color.bgBase)
}
