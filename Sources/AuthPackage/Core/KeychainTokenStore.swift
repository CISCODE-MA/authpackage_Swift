//
//  KeychainTokenStore.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation
import Security

public final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String

    public init(
        service: String = "com.example.authpackage",
        account: String = "auth_tokens"
    ) {
        self.service = service
        self.account = account
    }

    public func save(_ tokens: Tokens) throws {
        let dict: [String: Any?] = [
            "accessToken": tokens.accessToken,
            "refreshToken": tokens.refreshToken,
            "expiry": tokens.expiry?.timeIntervalSince1970,
        ]
        let data = try JSONSerialization.data(
            withJSONObject: dict.compactMapValues { $0 })

        try deleteItem()
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(q as CFDictionary, nil)
        guard status == errSecSuccess else { throw APIError.unknown }
    }

    public func load() throws -> Tokens? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var r: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &r)
        guard status == errSecSuccess, let data = r as? Data else { return nil }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let access = obj?["accessToken"] as? String ?? ""
        let refresh = obj?("refreshToken") as? String ?? ""
        let expiry = (obj?["expiry"] as? TimeInterval).map(
            Date.init(timeIntervalSince1970:))
        return tokens(
            accessToken: access, refreshToken: refresh, expiry: expiry)

    }

    public func clear() throws { try deleteItem() }

    private func deleteItem() throws {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(q as CFDictionary)
    }
}
