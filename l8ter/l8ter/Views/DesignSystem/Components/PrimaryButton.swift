import SwiftUI

/// Solid purple CTA. 14pt semibold, dark text on accent background.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var disabled: Bool = false
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
            .foregroundStyle(disabled ? Color.textDisabled : Color.bgBase)
            .background(disabled ? Color.bgRaised : Color.accent)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.button))
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "Open in Maps", systemImage: "play.fill") {}
        PrimaryButton(title: "Save", disabled: true) {}
    }
    .padding(40)
    .background(Color.bgBase)
}
