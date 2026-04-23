import Foundation

/// Web-search-backed enrichment for movies and shows. Runs after the
/// initial extraction to fill in canonical year / director / creator /
/// network / where-to-watch. Best-effort: returns nil on any failure;
/// the caller falls back to whatever the post provided.
enum MediaLookup {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-haiku-4-5"
    private static let anthropicVersion = "2023-06-01"
    private static let maxTokens = 1024

    struct MovieResult: Decodable {
        let title: String?
        let year: Int?
        let director: String?
        let genre: String?
        let whereToWatch: String?
        let confidence: Double
        let reasoning: String

        enum CodingKeys: String, CodingKey {
            case title, year, director, genre, confidence, reasoning
            case whereToWatch = "where_to_watch"
        }
    }

    struct ShowResult: Decodable {
        let title: String?
        let creator: String?
        let network: String?
        let genre: String?
        let whereToWatch: String?
        let confidence: Double
        let reasoning: String

        enum CodingKeys: String, CodingKey {
            case title, creator, network, genre, confidence, reasoning
            case whereToWatch = "where_to_watch"
        }
    }

    private static let webSearchTool: [String: Any] = [
        "type": "web_search_20250305",
        "name": "web_search",
        "max_uses": 3
    ]

    private static let movieSystemPrompt = """
    You verify and enrich metadata for a film the user saved from a \
    social-media reel. Use the web_search tool to find the canonical \
    title, release year, director, genre, and current US streaming \
    availability. Prefer authoritative sources (Wikipedia, Letterboxd, \
    JustWatch, IMDb).

    Use the context provided to disambiguate (e.g., the reel may say \
    "Dune" but mean the 2021 or 1984 version). If you cannot pick one \
    confidently, leave fields null.

    Do not invent facts. `reasoning` is one short sentence naming your \
    source. Finish by calling record_movie.
    """

    private static let showSystemPrompt = """
    You verify and enrich metadata for a TV series or streaming show the \
    user saved from a social-media reel. Use the web_search tool to find \
    the canonical title, creator, original network, genre, and current \
    US streaming availability.

    Use the context to disambiguate. If you cannot pick one confidently, \
    leave fields null. Do not invent. `reasoning` is one short sentence \
    naming your source. Finish by calling record_show.
    """

    private static let movieTool: [String: Any] = [
        "name": "record_movie",
        "description": "Record verified movie metadata.",
        "input_schema": [
            "type": "object",
            "required": ["title", "year", "director", "genre", "where_to_watch", "confidence", "reasoning"],
            "properties": [
                "title": ["type": ["string", "null"]],
                "year": ["type": ["integer", "null"]],
                "director": ["type": ["string", "null"]],
                "genre": ["type": ["string", "null"]],
                "where_to_watch": ["type": ["string", "null"]],
                "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                "reasoning": ["type": "string"]
            ]
        ]
    ]

    private static let showTool: [String: Any] = [
        "name": "record_show",
        "description": "Record verified show metadata.",
        "input_schema": [
            "type": "object",
            "required": ["title", "creator", "network", "genre", "where_to_watch", "confidence", "reasoning"],
            "properties": [
                "title": ["type": ["string", "null"]],
                "creator": ["type": ["string", "null"]],
                "network": ["type": ["string", "null"]],
                "genre": ["type": ["string", "null"]],
                "where_to_watch": ["type": ["string", "null"]],
                "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                "reasoning": ["type": "string"]
            ]
        ]
    ]

    static func lookupMovie(from m: MovieExtraction) async throws -> MovieResult {
        let userText = """
        Extracted title: \(m.title)
        Year hint: \(m.year.map(String.init) ?? "(unknown)")
        Director hint: \(m.director ?? "(unknown)")
        Genre hint: \(m.genre ?? "(unknown)")
        Where to watch hint: \(m.whereToWatch ?? "(unknown)")

        Verify and enrich.
        """
        return try await call(
            systemPrompt: movieSystemPrompt,
            recordingTool: movieTool,
            recordingToolName: "record_movie",
            userText: userText
        )
    }

    static func lookupShow(from s: ShowExtraction) async throws -> ShowResult {
        let userText = """
        Extracted title: \(s.title)
        Creator hint: \(s.creator ?? "(unknown)")
        Network hint: \(s.network ?? "(unknown)")
        Genre hint: \(s.genre ?? "(unknown)")
        Where to watch hint: \(s.whereToWatch ?? "(unknown)")

        Verify and enrich.
        """
        return try await call(
            systemPrompt: showSystemPrompt,
            recordingTool: showTool,
            recordingToolName: "record_show",
            userText: userText
        )
    }

    private static func call<T: Decodable>(
        systemPrompt: String,
        recordingTool: [String: Any],
        recordingToolName: String,
        userText: String
    ) async throws -> T {
        guard let apiKey = try KeychainStore.load(KeychainStore.claudeAPIKeyAccount),
              !apiKey.isEmpty else {
            throw ClaudeExtractorError.missingAPIKey
        }

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "tools": [webSearchTool, recordingTool],
            "messages": [
                [
                    "role": "user",
                    "content": [["type": "text", "text": userText]]
                ]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (respData, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse else {
            throw ClaudeExtractorError.apiError(statusCode: -1, body: "no http response")
        }
        if http.statusCode != 200 {
            let body = String(data: respData, encoding: .utf8) ?? ""
            throw ClaudeExtractorError.apiError(statusCode: http.statusCode, body: body)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let use = content.last(where: {
                ($0["type"] as? String) == "tool_use"
                    && ($0["name"] as? String) == recordingToolName
            }),
            let input = use["input"] as? [String: Any]
        else {
            throw ClaudeExtractorError.noToolUseInResponse
        }

        let data = try JSONSerialization.data(withJSONObject: input)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ClaudeExtractorError.decodingFailed(error)
        }
    }
}
