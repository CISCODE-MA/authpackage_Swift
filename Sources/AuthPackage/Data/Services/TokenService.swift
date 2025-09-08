//
//  TokenService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol TokenServicing {
    func refres(using refreshToken: String?) async throws -> String
    func logout(accessToken: String) async throws -> String?
    func checkToken(_ token: String) async throws -> String?
}

public final class TokenService: TokenServicing {
    private let config: AuthConfiguration
    private let net: NetworkClient
    private let tokens: TokenStore

    public init(
        config: AuthConfiguration, net: NetworkClient, tokens: TokenStore
    ) {
        self.config = config
        self.net = net
        self.tokens = tokens
    }

    public func refresh(using refreshToken: String?) async throws -> String {
        // If using HTTPOnly cookie for refresh, body token can be nil; otherwize pass it .
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL, path: Endpoints.refresh, method: .POST,
            headers: [:], body: ["refreshToken": refreshToken as Any])

        guard let newAccess = env.accessToken else { throw APIError.unknown }
        let current = try tokens.load()
        try tokens.save(
            Tokens(
                accessToken: newAccess,
                refreshToken: current?.refreshToken ?? refreshToken))
        return newAccess
    }

    public func logout(accessToken: String) async throws -> String? {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL, path: Endpoints.logout, method: .POST,
            headers: ["Authorization": "Bearer \(accessToken)"], body: nil)
        try? tokens.clear()
        return env.message
    }

    public func checkToken(_ token: String) async throws -> String? {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL, path: Endpoints.checkToken, method: .POST,
            headers: [:], body: ["token": token])
        return env.message
    }
}
