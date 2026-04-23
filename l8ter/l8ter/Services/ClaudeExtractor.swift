import Foundation

/// The structured result of a single extraction call.
struct ExtractionResult: Decodable {
    let category: String
    let confidence: Double
    let title: String
    let reasoning: String
    let summary: String?
    let restaurant: RestaurantExtraction?
    let movie: MovieExtraction?
    let show: ShowExtraction?
}

struct RestaurantExtraction: Decodable {
    let name: String
    let address: String?
    let city: String?
    let cuisine: String?
    let notableDishes: [String]

    enum CodingKeys: String, CodingKey {
        case name, address, city, cuisine
        case notableDishes = "notable_dishes"
    }
}

struct MovieExtraction: Decodable {
    let title: String
    let year: Int?
    let director: String?
    let genre: String?
    let whereToWatch: String?

    enum CodingKeys: String, CodingKey {
        case title, year, director, genre
        case whereToWatch = "where_to_watch"
    }
}

struct ShowExtraction: Decodable {
    let title: String
    let creator: String?
    let network: String?
    let genre: String?
    let whereToWatch: String?

    enum CodingKeys: String, CodingKey {
        case title, creator, network, genre
        case whereToWatch = "where_to_watch"
    }
}

enum ClaudeExtractorError: Error {
    case missingAPIKey
    case thumbnailURLMissing
    case thumbnailDownloadFailed(statusCode: Int)
    case apiError(statusCode: Int, body: String)
    case noToolUseInResponse
    case decodingFailed(Error)
}

/// Sends a TikTok oEmbed payload + thumbnail to Claude for
/// categorization and field extraction. Returns a typed result.
enum ClaudeExtractor {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-haiku-4-5"
    private static let anthropicVersion = "2023-06-01"
    private static let maxTokens = 512

    /// Phase 7: registry-driven. The stable system prompt below is cached
    /// for hit rate; the current category list (built-in + user-defined)
    /// is injected into each user turn.
    static let systemPrompt = """
    You categorize short-form video posts (TikTok/Instagram reels) that \
    users have saved as "things to remember." You will be given a list \
    of categories the user has set up, each with a description of what \
    qualifies. Pick exactly one category per post.

    RULES
    1. Use only information present in the caption, author fields, and \
       thumbnail image. Never invent facts. Unknown fields are null.
    2. If you are less than 50% confident about the category, use \
       `uncategorized`.
    3. Populate only the structured detail object matching the chosen \
       category (restaurant, movie, or show). The others must be null. \
       If the chosen category has no structured details, leave all three \
       null.
    4. `summary` is a concise 1–2 sentence description of the post \
       capturing what the user would want to remember. Required for \
       categories without structured details; optional for restaurant / \
       movie / show (may be null).
    5. notable_dishes only contains dishes explicitly named in the \
       caption. Do not infer.
    6. The top-level `title` is short and human-friendly for display \
       (the restaurant / movie / show name when known; otherwise a terse \
       handle for the post). Max 60 chars.

    Call the record_extraction tool with the extracted fields. Do not \
    write any prose response.
    """

    private static func toolSchema(categoryNames: [String]) -> [String: Any] {
        [
        "name": "record_extraction",
        "description": "Record the categorization and extracted fields for a saved reel.",
        "input_schema": [
            "type": "object",
            "required": [
                "category", "confidence", "title", "reasoning", "summary",
                "restaurant", "movie", "show"
            ],
            "properties": [
                "category": [
                    "type": "string",
                    "enum": categoryNames
                ],
                "confidence": [
                    "type": "number",
                    "minimum": 0,
                    "maximum": 1
                ],
                "title": [
                    "type": "string",
                    "description": "Short display title. Max 60 chars."
                ],
                "reasoning": [
                    "type": "string",
                    "description": "One short sentence explaining the decision."
                ],
                "summary": [
                    "type": ["string", "null"],
                    "description": "1–2 sentence summary capturing what the user would want to remember. Required for categories without structured details."
                ],
                "restaurant": [
                    "type": ["object", "null"],
                    "description": "Populate only when category is 'restaurant'. Null otherwise.",
                    "required": ["name", "address", "city", "cuisine", "notable_dishes"],
                    "properties": [
                        "name": ["type": "string"],
                        "address": [
                            "type": ["string", "null"],
                            "description": "Full street address if explicitly stated. Null otherwise."
                        ],
                        "city": [
                            "type": ["string", "null"],
                            "description": "City name if stated or clearly implied by author/hashtags."
                        ],
                        "cuisine": ["type": ["string", "null"]],
                        "notable_dishes": [
                            "type": "array",
                            "items": ["type": "string"]
                        ]
                    ]
                ],
                "movie": [
                    "type": ["object", "null"],
                    "description": "Populate only when category is 'movie'. Null otherwise.",
                    "required": ["title", "year", "director", "genre", "where_to_watch"],
                    "properties": [
                        "title": ["type": "string"],
                        "year": ["type": ["integer", "null"]],
                        "director": ["type": ["string", "null"]],
                        "genre": ["type": ["string", "null"]],
                        "where_to_watch": [
                            "type": ["string", "null"],
                            "description": "Only if stated in the post (e.g. 'on Netflix'). Null otherwise."
                        ]
                    ]
                ],
                "show": [
                    "type": ["object", "null"],
                    "description": "Populate only when category is 'show'. Null otherwise.",
                    "required": ["title", "creator", "network", "genre", "where_to_watch"],
                    "properties": [
                        "title": ["type": "string"],
                        "creator": ["type": ["string", "null"]],
                        "network": [
                            "type": ["string", "null"],
                            "description": "Original network or streamer if stated (HBO, Netflix, etc.)."
                        ],
                        "genre": ["type": ["string", "null"]],
                        "where_to_watch": [
                            "type": ["string", "null"]
                        ]
                    ]
                ]
            ]
        ]
        ]
    }

    /// Human-readable listing of available categories, injected into
    /// the user turn. Built fresh per call to reflect the current
    /// registry (built-in + user-defined).
    private static func categoryListing(_ options: [CategoryOption]) -> String {
        options.map { "- \($0.name): \($0.description)" }
            .joined(separator: "\n")
    }

    static func extract(
        oEmbed: TikTokOEmbedResponse,
        sourceURL: String,
        platform: String = "tiktok",
        categoryOptions: [CategoryOption]
    ) async throws -> ExtractionResult {
        guard let apiKey = try KeychainStore.load(KeychainStore.claudeAPIKeyAccount),
              !apiKey.isEmpty else {
            throw ClaudeExtractorError.missingAPIKey
        }
        guard let thumbURLString = oEmbed.thumbnailURL,
              let thumbURL = URL(string: thumbURLString) else {
            throw ClaudeExtractorError.thumbnailURLMissing
        }

        let (imageData, imageResponse) = try await URLSession.shared.data(from: thumbURL)
        if let http = imageResponse as? HTTPURLResponse, http.statusCode != 200 {
            throw ClaudeExtractorError.thumbnailDownloadFailed(statusCode: http.statusCode)
        }
        let mediaType = (imageResponse as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Type") ?? "image/jpeg"
        let base64Image = imageData.base64EncodedString()

        let userText = """
        AVAILABLE CATEGORIES
        \(categoryListing(categoryOptions))

        POST
        Platform: \(platform)
        Author name: \(oEmbed.authorName ?? "unknown")
        Author handle: @\(oEmbed.authorUniqueID ?? "unknown")
        Caption: \(oEmbed.title ?? "(no caption)")
        Source URL: \(sourceURL)
        """

        let categoryNames = categoryOptions.map(\.name)
        let payload: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": [
                [
                    "type": "text",
                    "text": systemPrompt,
                    "cache_control": ["type": "ephemeral"]
                ]
            ],
            "tools": [toolSchema(categoryNames: categoryNames)],
            "tool_choice": ["type": "tool", "name": "record_extraction"],
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": mediaType,
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": userText
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (respData, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse else {
            throw ClaudeExtractorError.apiError(statusCode: -1, body: "no http response")
        }
        if http.statusCode != 200 {
            let bodyText = String(data: respData, encoding: .utf8) ?? ""
            throw ClaudeExtractorError.apiError(statusCode: http.statusCode, body: bodyText)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let toolUse = content.first(where: { ($0["type"] as? String) == "tool_use" }),
            let input = toolUse["input"] as? [String: Any]
        else {
            throw ClaudeExtractorError.noToolUseInResponse
        }

        let inputData = try JSONSerialization.data(withJSONObject: input)
        do {
            return try JSONDecoder().decode(ExtractionResult.self, from: inputData)
        } catch {
            throw ClaudeExtractorError.decodingFailed(error)
        }
    }
}
