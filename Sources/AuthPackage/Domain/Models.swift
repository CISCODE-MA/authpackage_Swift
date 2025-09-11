//
//  Models.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

/// Canonical user shape aligned with backend (clients + users).
public struct User: Codable, Equatable, Sendable {
    public let id: String
    public let email: String
    public let name: String?
    public let tenantId: String?          // backend may omit; keep optional
    public let roles: [String]
    public let permissions: [String]

    public init(
        id: String,
        email: String,
        name: String?,
        tenantId: String?,
        roles: [String],
        permissions: [String]
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.tenantId = tenantId
        self.roles = roles
        self.permissions = permissions
    }
}

/// Tokens we store locally.
public struct Tokens: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?

    public init(accessToken: String, refreshToken: String?, expiry: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
