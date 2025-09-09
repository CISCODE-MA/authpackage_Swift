//
//  TokenService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol TokenServicing {
    /// Refreshes using HttpOnly refresh cookie (no request body).
    @discardableResult
    func refresh(using refreshToken: String?) async throws -> String

    /// Logout with current access token (Authorization header).
    func logout(accessToken: String) async throws -> String?

    // (keep the interface; omit "checkToken" as it's for manual testing only)
}

public struct TokenService: TokenServicing {
    private let config: AuthConfiguration
    private let net: NetworkClient
    private let tokens: TokenStore

    public init(
        config: AuthConfiguration,
        net: NetworkClient,
        tokens: TokenStore
    ) {
        self.config = config
        self.net = net
        self.tokens = tokens
    }

    public func refresh(using refreshToken: String?) async throws -> String {
        // Cookie-based: server reads refresh token from HttpOnly cookie
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.refresh,  // /api/auth/refresh-token
            method: .POST,
            headers: [:],
            body: nil
        )  // cookie flow per your API collection :contentReference[oaicite:5]{index=5}

        guard let newAccess = env.accessToken else { throw APIError.unknown }
        // Persist new access; keep any stored refresh if you have one (not required for cookie mode)
        let current = try tokens.load()
        try tokens.save(
            Tokens(
                accessToken: newAccess,
                refreshToken: current?.refreshToken,
                expiry: current?.expiry
            )
        )
        return newAccess
    }

    public func logout(accessToken: String) async throws -> String? {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.logout,
            method: .POST,
            headers: ["Authorization": "Bearer \(accessToken)"],
            body: nil
        )
        try? tokens.clear()
        return env.message
    }
}
