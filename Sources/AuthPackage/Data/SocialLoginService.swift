//
//  SocialLoginService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

import Foundation

public protocol SocialLoginServicing {
    func exchange(credential: SocialCredential) async throws -> (
        message: String?, user: User?, accessToken: String?
    )
}

public final class SocialLoginService: SocialLoginServicing {
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

    public func exchange(credential: SocialCredential) async throws -> (
        message: String?, user: User?, accessToken: String?
    ) {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.socialLogin,
            method: .POST,
            headers: [:],
            body: [
                "provider": credential.provider.rawValue,
                "idToken": credential.idToken as Any,
                "accessToken": credential.accessToken as Any,
            ].compactMapValues { $0 }
        )

        if let access = env.accessToken {
            try? tokens.save(Tokens(accessToken: access))
        }

        return (env.message, env.user.map(Mapper.user), env.accessToken)
    }
}
