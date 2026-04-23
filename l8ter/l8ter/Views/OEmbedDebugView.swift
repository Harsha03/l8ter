import SwiftUI

/// Debug screen for inspecting TikTok oEmbed responses.
/// Paste a reel URL, hit Fetch, see decoded fields + raw JSON.
struct OEmbedDebugView: View {
    @State private var reelURL = ""
    @State private var result: TikTokOEmbedFetchResult?
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        Form {
            Section("TikTok Reel URL") {
                TextField("https://www.tiktok.com/@user/video/...", text: $reelURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Fetch") {
                    Task { await fetch() }
                }
                .disabled(reelURL.isEmpty || isLoading)
            }

            if isLoading {
                Section { ProgressView() }
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            }

            if let response = result?.response {
                Section("Decoded") {
                    row("title", response.title)
                    row("author_name", response.authorName)
                    row("author_unique_id", response.authorUniqueID)
                    row("thumbnail_url", response.thumbnailURL)
                    row("provider_name", response.providerName)
                }
            }

            if let rawJSON = result?.rawJSON {
                Section("Raw JSON") {
                    Text(rawJSON)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("oEmbed Test")
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

    private func fetch() async {
        isLoading = true
        errorMessage = nil
        result = nil
        defer { isLoading = false }

        do {
            result = try await TikTokOEmbed.fetch(reelURL: reelURL)
        } catch {
            errorMessage = "\(error)"
        }
    }
}

#Preview {
    NavigationStack { OEmbedDebugView() }
}
