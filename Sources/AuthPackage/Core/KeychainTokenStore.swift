//
//  KeychainTokenStore.swift
//  AuthPackage
//

import Foundation
import Security

// MARK: - Tiny seam to make Keychain testable

public protocol KeychainClient {
    func add(_ query: CFDictionary) -> OSStatus
    func update(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus
    func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func delete(_ query: CFDictionary) -> OSStatus
}

public struct RealKeychainClient: KeychainClient {
    public init() {}
    public func add(_ query: CFDictionary) -> OSStatus { SecItemAdd(query, nil) }
    public func update(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus {
        SecItemUpdate(query, attributesToUpdate)
    }
    public func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        SecItemCopyMatching(query, result)
    }
    public func delete(_ query: CFDictionary) -> OSStatus { SecItemDelete(query) }
}

// MARK: - Store

public final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String
    private let keychain: KeychainClient

    public init(
        service: String = "com.example.authpackage",
        account: String = "auth.tokens",
        keychain: KeychainClient = RealKeychainClient()
    ) {
        self.service = service
        self.account = account
        self.keychain = keychain
    }

    public func save(_ tokens: Tokens) throws {
        // encode Tokens -> Data (no need for Tokens to be Codable)
        let payload: [String: Any?] = [
            "accessToken": tokens.accessToken,
            "refreshToken": tokens.refreshToken
        ]
        let data = try JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 }, options: [])

        // Build the “find” query
        let find: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        // Attributes to set
        let addAttrs: [String: Any] = find.merging([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]) { $1 }

        // Try add; on duplicate, update
        let status = keychain.add(addAttrs as CFDictionary)
        if status == errSecDuplicateItem {
            let updateStatus = keychain.update(find as CFDictionary,
                                               [kSecValueData as String: data] as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw map(status: updateStatus)
            }
        } else if status != errSecSuccess {
            throw map(status: status)
        }
    }

    public func load() throws -> Tokens? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var out: CFTypeRef?
        let status = keychain.copyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = out as? Data else {
            throw map(status: status)
        }
        // decode Data -> Tokens
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
        let access = json["accessToken"] as? String
        let refresh = json["refreshToken"] as? String
        let expiry: Date?
        if let t = json["expiry"] as? Double { expiry = Date(timeIntervalSince1970: t) } else { expiry = nil }
        guard let accessToken = access else { return nil }
        return Tokens(accessToken: accessToken, refreshToken: refresh, expiry: expiry)
    }

    public func clear() throws {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = keychain.delete(q as CFDictionary)
        // Clearing a missing item is not an error from the store’s perspective
        if status != errSecSuccess && status != errSecItemNotFound {
            throw map(status: status)
        }
    }

    // MARK: - Status mapping

    private func map(status: OSStatus) -> APIError {
        switch status {
        case errSecUserCanceled:      return .unauthorized
        case errSecNotAvailable:      return .network("Keychain not available")
        case errSecAuthFailed:        return .unauthorized
        default:                      return .network("Keychain status \(status)")
        }
    }
}
