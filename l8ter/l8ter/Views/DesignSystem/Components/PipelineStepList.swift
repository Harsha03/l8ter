import SwiftUI

/// Vertical list of pipeline steps used in the Add tab during save.
/// Each step has a label and a state (todo / active / done) plus an
/// optional duration string shown on the right in mono.
struct PipelineStepList: View {
    let steps: [Step]

    struct Step: Identifiable {
        let id = UUID()
        let label: String
        let state: State
        let duration: String?
    }

    enum State {
        case todo
        case active
        case done
    }

    var body: some View {
        CardSurface(elevation: .sunken) {
            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(spacing: 12) {
                        dot(for: step.state)
                        Text(step.label.uppercased())
                            .font(.dsMetaCaps)
                            .tracking(1.0)
                            .foregroundStyle(labelColor(for: step.state))
                        Spacer(minLength: 0)
                        Text(step.duration ?? "—")
                            .font(.dsMetaSmall)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(Color.borderHairline)
                            .frame(height: 0.5)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dot(for state: State) -> some View {
        switch state {
        case .todo:
            Circle().fill(Color.borderQuiet).frame(width: 8, height: 8)
        case .active:
            Pulse(animated: true).scaleEffect(1.6)
        case .done:
            Circle()
                .fill(Color.accent)
                .frame(width: 8, height: 8)
                .shadow(color: Color.accent.opacity(0.6), radius: 4)
        }
    }

    private func labelColor(for state: State) -> Color {
        switch state {
        case .todo:   return .textDisabled
        case .active: return .accent
        case .done:   return .textPrimary
        }
    }
}

#Preview {
    PipelineStepList(steps: [
        .init(label: "Fetched oEmbed", state: .done, duration: "0.4s"),
        .init(label: "Saved thumbnail", state: .done, duration: "0.2s"),
        .init(label: "Asking Claude…", state: .active, duration: "…"),
        .init(label: "Verify address", state: .todo, duration: nil),
        .init(label: "Geocode", state: .todo, duration: nil)
    ])
    .padding(22)
    .background(Color.bgBase)
}
