//
//  LoginService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol LoginServicing {
    func login(email: String, password: String) async throws
        -> (message: String?, accessToken: String?, refreshToken: String?)
}

public final class LoginService: LoginServicing {
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

    public func login(email: String, password: String) async throws
    -> (message: String?,accessToken: String?,refreshToken: String?)
    {
        let headers = ["Content-Type": "application/json"]
        let body: [String: Any] = ["email": email, "password": password]

        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.login,  // /api/auth/clients/login
            method: .POST,
            headers: headers,
            body: body
        )
        if let access = env.accessToken {
            try? tokens.save(
                Tokens(accessToken: access, refreshToken: env.refreshToken)
            )
        }
        return (env.message, env.accessToken, env.refreshToken)
    }
}
