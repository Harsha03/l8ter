import SwiftUI
import SwiftData

/// End-to-end extraction debug screen.
/// Paste a TikTok URL, runs oEmbed → Claude, shows the typed result.
struct ExtractDebugView: View {
    @Environment(\.modelContext) private var context
    @State private var reelURL = ""
    @State private var oEmbed: TikTokOEmbedResponse?
    @State private var extraction: ExtractionResult?
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("TikTok Reel URL") {
                TextField("https://www.tiktok.com/@user/video/...", text: $reelURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Extract") {
                    Task { await run() }
                }
                .disabled(reelURL.isEmpty || isLoading)
            }

            if isLoading {
                Section { ProgressView() }
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }

            if let oEmbed {
                Section("oEmbed") {
                    row("caption", oEmbed.title)
                    row("author", oEmbed.authorName)
                    row("handle", oEmbed.authorUniqueID.map { "@\($0)" })
                    if let thumb = oEmbed.thumbnailURL,
                       let url = URL(string: thumb) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxHeight: 240)
                    }
                }
            }

            if let extraction {
                Section("Extraction") {
                    row("category", extraction.category)
                    row("confidence", String(format: "%.2f", extraction.confidence))
                    row("title", extraction.title)
                    row("reasoning", extraction.reasoning)
                }
                if let r = extraction.restaurant {
                    Section("Restaurant") {
                        row("name", r.name)
                        row("address", r.address)
                        row("city", r.city)
                        row("cuisine", r.cuisine)
                        row("notable dishes", r.notableDishes.isEmpty ? nil : r.notableDishes.joined(separator: ", "))
                    }
                }
            }
        }
        .navigationTitle("Extract Test")
    }

    @ViewBuilder
    private func row(_ key: String, _ value: String?) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "—")
                .font(.caption)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    private func run() async {
        isLoading = true
        errorMessage = nil
        oEmbed = nil
        extraction = nil
        defer { isLoading = false }

        do {
            let fetch = try await TikTokOEmbed.fetch(reelURL: reelURL)
            oEmbed = fetch.response
            let customs = (try? context.fetch(FetchDescriptor<CustomCategory>())) ?? []
            let options = CategoryRegistry.options(customCategories: customs)
            extraction = try await ClaudeExtractor.extract(
                oEmbed: fetch.response,
                sourceURL: reelURL,
                platform: "tiktok",
                categoryOptions: options
            )
        } catch {
            errorMessage = "\(error)"
        }
    }
}

#Preview {
    NavigationStack { ExtractDebugView() }
}
