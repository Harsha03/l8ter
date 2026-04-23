import Foundation

/// Result of a web-search-backed address lookup.
struct AddressLookupResult: Decodable {
    let address: String?
    let city: String?
    let confidence: Double
    let reasoning: String

    enum CodingKeys: String, CodingKey {
        case address, city, confidence, reasoning
    }
}

enum AddressLookupError: Error {
    case missingAPIKey
    case apiError(statusCode: Int, body: String)
    case noToolUseInResponse
    case decodingFailed(Error)
}

/// Uses Claude with the `web_search` server tool to find (or verify)
/// the street address of a named restaurant. Called after the initial
/// extraction, for every restaurant, whether or not the post already
/// contained an address.
enum AddressLookup {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-haiku-4-5"
    private static let anthropicVersion = "2023-06-01"
    private static let maxTokens = 1024

    private static let systemPrompt = """
    You verify and look up street addresses for restaurants using web \
    search. You will be given a restaurant name plus any context that \
    was available from the original social-media post (caption, city, \
    post-provided address, author handle).

    PROCESS
    1. Use the web_search tool to find the restaurant's canonical street \
       address. Prefer authoritative sources (the restaurant's own \
       website, Google Maps, Yelp, OpenTable).
    2. Disambiguate using the supplied context (city, cuisine, \
       neighborhood, author). If there are multiple locations with the \
       same name, pick the one that best matches the context. If you \
       cannot confidently pick one, leave the address null.
    3. Return the full street address in `address` and the city in \
       `city`. Do not invent an address you did not see in the results.
    4. Provide a confidence 0.0–1.0 reflecting how sure you are this is \
       the right venue.
    5. `reasoning` is one short sentence naming the source and any \
       disambiguation you did. No prose outside the tool call.

    Always finish by calling the record_address tool.
    """

    private static let recordAddressTool: [String: Any] = [
        "name": "record_address",
        "description": "Record the verified street address for the restaurant.",
        "input_schema": [
            "type": "object",
            "required": ["address", "city", "confidence", "reasoning"],
            "properties": [
                "address": [
                    "type": ["string", "null"],
                    "description": "Full street address. Null if not confidently found."
                ],
                "city": [
                    "type": ["string", "null"]
                ],
                "confidence": [
                    "type": "number",
                    "minimum": 0,
                    "maximum": 1
                ],
                "reasoning": [
                    "type": "string",
                    "description": "One short sentence. Cite the source."
                ]
            ]
        ]
    ]

    private static let webSearchTool: [String: Any] = [
        "type": "web_search_20250305",
        "name": "web_search",
        "max_uses": 3
    ]

    static func lookup(
        name: String,
        postAddress: String?,
        city: String?,
        cuisine: String?,
        authorHandle: String?
    ) async throws -> AddressLookupResult {
        guard let apiKey = try KeychainStore.load(KeychainStore.claudeAPIKeyAccount),
              !apiKey.isEmpty else {
            throw AddressLookupError.missingAPIKey
        }

        let userText = """
        Restaurant name: \(name)
        Post-provided address: \(postAddress ?? "(none)")
        City hint: \(city ?? "(unknown)")
        Cuisine hint: \(cuisine ?? "(unknown)")
        Author handle: \(authorHandle.map { "@\($0)" } ?? "(unknown)")

        Look up this restaurant's canonical street address.
        """

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "tools": [webSearchTool, recordAddressTool],
            "messages": [
                [
                    "role": "user",
                    "content": [
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
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (respData, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse else {
            throw AddressLookupError.apiError(statusCode: -1, body: "no http response")
        }
        if http.statusCode != 200 {
            let bodyText = String(data: respData, encoding: .utf8) ?? ""
            throw AddressLookupError.apiError(statusCode: http.statusCode, body: bodyText)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
            let content = json["content"] as? [[String: Any]]
        else {
            throw AddressLookupError.noToolUseInResponse
        }

        // Find the record_address tool_use (Claude may have used web_search
        // multiple times before calling our recording tool).
        guard
            let recordUse = content.last(where: {
                ($0["type"] as? String) == "tool_use"
                    && ($0["name"] as? String) == "record_address"
            }),
            let input = recordUse["input"] as? [String: Any]
        else {
            throw AddressLookupError.noToolUseInResponse
        }

        let inputData = try JSONSerialization.data(withJSONObject: input)
        do {
            return try JSONDecoder().decode(AddressLookupResult.self, from: inputData)
        } catch {
            throw AddressLookupError.decodingFailed(error)
        }
    }
}
