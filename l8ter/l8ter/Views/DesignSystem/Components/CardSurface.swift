import SwiftUI

/// A raised or sunken panel surface with hairline border. Use as a
/// container for inputs, pipeline step lists, or confidence panels.
struct CardSurface<Content: View>: View {
    var elevation: Elevation = .raised
    @ViewBuilder var content: () -> Content

    enum Elevation {
        case raised
        case sunken
    }

    var body: some View {
        content()
            .background(elevation == .raised ? Color.bgRaised : Color.bgSunken)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.card)
                    .strokeBorder(Color.borderHairline, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.card))
    }
}
