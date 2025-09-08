//
//  OTPService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol OTPServicing {
    func verify(identifier: String, otp: String) async throws -> (
        message: String?, user: User?, accessToken: String?
    )
}

public final class OTPService: OTPServicing {
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

    public func verify(identifier: String, otp: String) async throws -> (
        String?, User?, String?
    ) {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.verifyOTP,
            method: .POST,
            headers: [:],
            body: ["identifier": identifier, "otp": otp]
        )
        if let access = env.accessToken {
            try? tokens.save(Tokens(accessToken: access))
        }
        return (env.message, env.user.map(Mapper.user), env.accessToken)
    }
}
