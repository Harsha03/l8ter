import SwiftUI
import SwiftData

/// Paste-URL capture screen. Three states: idle → processing → saved.
struct CaptureView: View {
    @Environment(\.modelContext) private var context

    @State private var reelURL: String = ""
    @State private var phase: Phase = .idle
    @State private var progress = CaptureProgress()
    @State private var savedItem: SavedItemSnapshot?
    @State private var errorMessage: String?

    enum Phase {
        case idle
        case processing
        case saved
        case failed
    }

    /// Lightweight snapshot used to render the success card without
    /// holding a SwiftData reference across the async boundary.
    struct SavedItemSnapshot {
        let title: String
        let category: String
        let confidence: Double
        let thumbnailPath: String?
        let itemID: UUID
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgBase.ignoresSafeArea()
                content
            }
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: DSSpace.xl) {
            header

            switch phase {
            case .idle:
                idleBody
            case .processing:
                processingBody
            case .saved:
                savedBody
            case .failed:
                failedBody
            }

            Spacer()

            footer
        }
        .padding(.horizontal, DSSpace.xxl)
        .padding(.top, DSSpace.lg)
        .padding(.bottom, DSSpace.xxl)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            MetaLabel(text: phaseLabel, pulsing: phase == .processing, tone: phase == .idle ? .neutral : .accent)
            Text(phaseTitle)
                .font(.dsScreenTitle)
                .tracking(DSTracking.screenTitle)
                .foregroundStyle(Color.textPrimary)
        }
    }

    // MARK: - Idle

    private var idleBody: some View {
        VStack(alignment: .leading, spacing: DSSpace.xl) {
            inputCard

            Text("Tap the share icon on any TikTok and copy the link. Paste it above.\n\nInstagram coming after Phase 4.5.")
                .font(.dsMetaSmall)
                .foregroundStyle(Color.textTertiary)
                .lineSpacing(4)
        }
    }

    private var inputCard: some View {
        CardSurface(elevation: .raised) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Paste URL")
                TextField("tiktok.com/@user/video/...", text: $reelURL)
                    .font(.dsBody)
                    .foregroundStyle(Color.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Processing

    private var processingBody: some View {
        VStack(alignment: .leading, spacing: DSSpace.xl) {
            CardSurface(elevation: .raised) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "Source")
                    Text(reelURL.isEmpty ? "—" : reelURL)
                        .font(.dsMetaSmall)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .opacity(0.6)

            PipelineStepList(steps: progress.stepsForUI)
        }
    }

    // MARK: - Saved

    @ViewBuilder
    private var savedBody: some View {
        if let saved = savedItem {
            VStack(alignment: .leading, spacing: DSSpace.lg) {
                HStack(spacing: DSSpace.lg) {
                    Group {
                        if let path = saved.thumbnailPath,
                           let url = ThumbnailStore.absoluteURL(for: path),
                           let data = try? Data(contentsOf: url),
                           let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else {
                            Rectangle().fill(Color.bgRaised)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: DSRadius.thumbLarge))

                    VStack(alignment: .leading, spacing: 3) {
                        MetaLabel(text: saved.category.uppercased(), tone: .accent)
                        Text(saved.title)
                            .font(.dsRowTitle)
                            .tracking(DSTracking.rowTitle)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(2)
                    }
                    Spacer()
                }

                CardSurface(elevation: .raised) {
                    VStack(alignment: .leading, spacing: DSSpace.sm) {
                        SectionLabel(text: "Confidence")
                        HStack(spacing: DSSpace.md) {
                            ConfidenceBar(value: saved.confidence, width: 220)
                            Spacer()
                            Text(String(format: "%.2f", saved.confidence))
                                .font(.dsMetaSmall)
                                .foregroundStyle(Color.accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
        }
    }

    // MARK: - Failed

    private var failedBody: some View {
        CardSurface(elevation: .raised) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Error")
                Text(errorMessage ?? "Unknown error")
                    .font(.dsMetaSmall)
                    .foregroundStyle(Color.accent)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Footer (CTA)

    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .idle:
            PrimaryButton(title: "Save", disabled: reelURL.isEmpty) {
                Task { await run() }
            }
        case .processing:
            EmptyView()
        case .saved:
            HStack(spacing: DSSpace.md) {
                GhostButton(title: "Add another") {
                    reset()
                }
                PrimaryButton(title: "View →") {
                    reset()
                }
            }
        case .failed:
            HStack(spacing: DSSpace.md) {
                GhostButton(title: "Reset") { reset() }
                PrimaryButton(title: "Try again") {
                    Task { await run() }
                }
            }
        }
    }

    // MARK: - Pipeline

    private func run() async {
        let url = reelURL
        guard !url.isEmpty else { return }
        phase = .processing
        progress = CaptureProgress()
        savedItem = nil
        errorMessage = nil

        do {
            progress.start(.fetchOEmbed)
            let fetch = try await TikTokOEmbed.fetch(reelURL: url)
            progress.complete(.fetchOEmbed)

            progress.complete(.saveThumbnail)

            progress.start(.askingClaude)
            let customs = (try? context.fetch(FetchDescriptor<CustomCategory>())) ?? []
            let options = CategoryRegistry.options(customCategories: customs)
            let extraction = try await ClaudeExtractor.extract(
                oEmbed: fetch.response,
                sourceURL: url,
                platform: "tiktok",
                categoryOptions: options
            )
            progress.complete(.askingClaude)

            if extraction.category == BuiltInCategory.restaurant.rawValue {
                progress.start(.verifyAddress)
            } else {
                progress.start(.lookupMetadata)
            }

            try await ItemSaver.save(
                extraction: extraction,
                oEmbed: fetch.response,
                sourceURL: url,
                context: context
            )
            if extraction.category == BuiltInCategory.restaurant.rawValue {
                progress.complete(.verifyAddress)
                progress.start(.geocode)
                progress.complete(.geocode)
            } else {
                progress.complete(.lookupMetadata)
            }

            savedItem = SavedItemSnapshot(
                title: extraction.title,
                category: extraction.category,
                confidence: extraction.confidence,
                thumbnailPath: nil,
                itemID: UUID()
            )
            reelURL = ""
            phase = .saved
        } catch {
            errorMessage = "\(error)"
            phase = .failed
        }
    }

    private func reset() {
        phase = .idle
        progress = CaptureProgress()
        savedItem = nil
        errorMessage = nil
    }

    // MARK: - Phase labels

    private var phaseLabel: String {
        switch phase {
        case .idle:       return "01 · IDLE"
        case .processing: return "02 · PROCESSING"
        case .saved:      return "03 · SAVED"
        case .failed:     return "!! · FAILED"
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .idle:       return "Add"
        case .processing: return "Saving…"
        case .saved:      return "Got it."
        case .failed:     return "Hmm."
        }
    }
}

/// Tracks the per-step state of a save run for the UI.
struct CaptureProgress {
    enum Step: CaseIterable {
        case fetchOEmbed
        case saveThumbnail
        case askingClaude
        case verifyAddress
        case lookupMetadata
        case geocode

        var label: String {
            switch self {
            case .fetchOEmbed:    return "Fetched oEmbed"
            case .saveThumbnail:  return "Saved thumbnail"
            case .askingClaude:   return "Asking Claude"
            case .verifyAddress:  return "Verify address"
            case .lookupMetadata: return "Lookup metadata"
            case .geocode:        return "Geocode"
            }
        }
    }

    private var states: [Step: PipelineStepList.State] = [:]
    private var startTimes: [Step: Date] = [:]
    private var durations: [Step: TimeInterval] = [:]

    var stepsForUI: [PipelineStepList.Step] {
        let ordered: [Step] = [.fetchOEmbed, .saveThumbnail, .askingClaude, .verifyAddress, .geocode]
        return ordered.map { step in
            let state = states[step] ?? .todo
            let duration = durations[step].map { String(format: "%.1fs", $0) }
            return PipelineStepList.Step(
                label: step.label,
                state: state,
                duration: state == .active ? "…" : duration
            )
        }
    }

    mutating func start(_ step: Step) {
        states[step] = .active
        startTimes[step] = Date()
    }

    mutating func complete(_ step: Step) {
        states[step] = .done
        if let started = startTimes[step] {
            durations[step] = Date().timeIntervalSince(started)
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
