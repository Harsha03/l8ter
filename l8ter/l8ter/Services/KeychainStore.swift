import Foundation
import Security

/// Errors surfaced from Keychain operations.
enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
    case encodingFailed
}

/// Thin wrapper over `SecItem*` for storing small secrets (API keys, tokens).
/// Items are keyed by `account` under a single service identifier.
/// Accessibility: readable after first unlock since boot, so extensions
/// can read values without requiring an active foreground unlock.
enum KeychainStore {
    private static let service = "com.bobbydylan.l8ter"

    /// Save a string value for the given account key. Overwrites existing.
    static func save(_ value: String, for account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Load the string value for an account key. Returns nil if not present.
    static func load(_ account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    /// Remove the value for an account key. Succeeds if already absent.
    static func delete(_ account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

extension KeychainStore {
    /// Standard account name for the Claude API key.
    static let claudeAPIKeyAccount = "claudeAPIKey"
}
