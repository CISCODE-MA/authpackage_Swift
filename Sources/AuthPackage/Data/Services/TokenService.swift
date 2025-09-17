//
//  TokenService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol TokenServicing {
    func refresh(refreshToken: String?) async throws -> String?
    func logout() async throws
}

public final class TokenService: TokenServicing {
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

    public func refresh(refreshToken: String? = nil) async throws -> String? {
        let supplied = refreshToken ?? (try? tokens.load())?.refreshToken
        let body: [String: Any]? = supplied.map { ["refreshToken": $0] }  // nil -> cookie path
        let env: AccessTokenEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.refresh,
            method: .POST,
            headers: [:],
            body: body
        )
        if let access = env.accessToken {
            let oldRefresh = (try? tokens.load())?.refreshToken
            try? tokens.save(
                Tokens(accessToken: access, refreshToken: oldRefresh)
            )
        }
        return env.accessToken
    }

    public func logout() async throws {
        // Try to tell the server, but regardless of what happens we clear local tokens.
        do {
            _ = try await net.send(
                baseURL: config.baseURL,
                path: Endpoints.logout,
                method: .POST,
                headers: [:],
                body: nil
            ) as EmptyResponse
        } catch {
            // Swallow server errors intentionally; local logout must still proceed.
        }
        try? tokens.clear()
    }

}

struct EmptyResponse: Decodable {}
