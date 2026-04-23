import SwiftUI
import SwiftData

/// Paste-URL capture screen. v1 stopgap until the share extension lands
/// in Phase 4. Runs the full pipeline: oEmbed → Claude → geocode → save.
struct CaptureView: View {
    @Environment(\.modelContext) private var context

    @State private var reelURL = ""
    @State private var status: Status = .idle

    enum Status {
        case idle
        case working(String)
        case success(String)
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("TikTok Reel URL") {
                    TextField("https://www.tiktok.com/@user/video/...", text: $reelURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Button("Save") {
                        Task { await run() }
                    }
                    .disabled(reelURL.isEmpty || isWorking)
                }

                switch status {
                case .idle:
                    EmptyView()
                case .working(let msg):
                    Section {
                        HStack {
                            ProgressView()
                            Text(msg).font(.caption)
                        }
                    }
                case .success(let msg):
                    Section {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                case .failure(let msg):
                    Section("Error") {
                        Text(msg)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Add")
        }
    }

    private var isWorking: Bool {
        if case .working = status { return true }
        return false
    }

    private func run() async {
        let url = reelURL
        status = .working("Fetching oEmbed…")

        do {
            let fetch = try await TikTokOEmbed.fetch(reelURL: url)
            status = .working("Extracting…")
            let customs = (try? context.fetch(FetchDescriptor<CustomCategory>())) ?? []
            let options = CategoryRegistry.options(customCategories: customs)
            let extraction = try await ClaudeExtractor.extract(
                oEmbed: fetch.response,
                sourceURL: url,
                platform: "tiktok",
                categoryOptions: options
            )
            status = .working("Saving…")
            try await ItemSaver.save(
                extraction: extraction,
                oEmbed: fetch.response,
                sourceURL: url,
                context: context
            )
            reelURL = ""
            status = .success("Saved: \(extraction.title)")
        } catch {
            status = .failure("\(error)")
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [Item.self, RestaurantDetails.self, MovieDetails.self, ShowDetails.self, CustomCategory.self], inMemory: true)
}
