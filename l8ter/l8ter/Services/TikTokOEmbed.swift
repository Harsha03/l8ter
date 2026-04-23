import Foundation

/// Decoded fields from TikTok's public oEmbed endpoint.
/// All fields are optional because TikTok occasionally omits them.
struct TikTokOEmbedResponse: Decodable {
    let title: String?
    let authorName: String?
    let authorUniqueID: String?
    let authorURL: String?
    let thumbnailURL: String?
    let thumbnailWidth: Int?
    let thumbnailHeight: Int?
    let html: String?
    let providerName: String?

    enum CodingKeys: String, CodingKey {
        case title
        case authorName = "author_name"
        case authorUniqueID = "author_unique_id"
        case authorURL = "author_url"
        case thumbnailURL = "thumbnail_url"
        case thumbnailWidth = "thumbnail_width"
        case thumbnailHeight = "thumbnail_height"
        case html
        case providerName = "provider_name"
    }
}

struct TikTokOEmbedFetchResult {
    let response: TikTokOEmbedResponse
    let rawJSON: String
}

enum TikTokOEmbedError: Error {
    case invalidURL
    case requestFailed(statusCode: Int)
}

enum TikTokOEmbed {
    /// Fetch oEmbed data for a TikTok reel URL.
    /// Returns the decoded struct plus the pretty-printed raw JSON for inspection.
    static func fetch(reelURL: String) async throws -> TikTokOEmbedFetchResult {
        guard var components = URLComponents(string: "https://www.tiktok.com/oembed") else {
            throw TikTokOEmbedError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "url", value: reelURL)]
        guard let url = components.url else {
            throw TikTokOEmbedError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw TikTokOEmbedError.requestFailed(statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(TikTokOEmbedResponse.self, from: data)
        let pretty = prettyPrint(data) ?? String(data: data, encoding: .utf8) ?? ""
        return TikTokOEmbedFetchResult(response: decoded, rawJSON: pretty)
    }

    private static func prettyPrint(_ data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(
                  withJSONObject: obj,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let string = String(data: pretty, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
