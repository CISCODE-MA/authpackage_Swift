//
//  LoginService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol LoginServicing {
    /// Logs in with identifier (email/username) and password.
    /// If device is trusted, backend returns an accessToken immediately (no OTP).
    /// If device is new/untrusted, backend returns otpCode (and NO tokens).
    func login(identifier: String, password: String, rememberMe: Bool)
        async throws -> (
            message: String?, user: User?, otpCode: String?, rememberMe: Bool?,
            accessToken: String?
        )
}

public final class LoginService: LoginServicing {
    private let config: AuthConfiguration
    private let net: NetworkClient

    public init(config: AuthConfiguration, net: NetworkClient) {
        self.config = config
        self.net = net
    }

    public func login(identifier: String, password: String, rememberMe: Bool)
        async throws -> (
            message: String?, user: User?, otpCode: String?, rememberMe: Bool?,
            accessToken: String?
        )
    {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.login,  // /api/auth/login
            method: .POST,
            headers: [:],
            body: [
                "identifier": identifier,
                "password": password,
                "rememberMe": rememberMe,
            ]
        )  // matches your current service contract :contentReference[oaicite:4]{index=4}
        return (
            message: env.message,
            user: env.user.map(Mapper.user),
            otpCode: env.otpCode,
            rememberMe: env.rememberMe,
            accessToken: env.accessToken  // NEW: capture token when OTP is skipped
        )
    }
}
