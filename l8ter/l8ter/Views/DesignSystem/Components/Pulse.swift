// l8ter/l8ter/Views/DesignSystem/Components/Pulse.swift
import SwiftUI

/// 5pt glowing purple dot. Used as the "alive" indicator next to
/// nearby items, the active processing step, and selected map pins.
struct Pulse: View {
    var animated: Bool = false

    @State private var dim = false

    var body: some View {
        Circle()
            .fill(Color.accent)
            .frame(width: 5, height: 5)
            .shadow(color: Color.accent.opacity(0.6), radius: 4)
            .opacity(dim ? 0.4 : 1.0)
            .onAppear {
                guard animated else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    dim = true
                }
            }
    }
}

#Preview {
    HStack(spacing: 20) {
        Pulse()
        Pulse(animated: true)
    }
    .padding(40)
    .background(Color.bgBase)
}
