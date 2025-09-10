//
//  Models.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public struct User: Equatable, Sendable {
    public let id: String
    public let email: String
    public let name: String?
    public let tenantId: String?
    public let roles: [String]
    public let permissions: [String]
}

public struct Tokens: Equatable, Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String?

    public init(accessToken: String, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
