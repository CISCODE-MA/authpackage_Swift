//
//  PasswordResetService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol PasswordResetServicing {
    func requestReset(email: String)
        async throws -> String?

    func reset(token: String, newPassword: String)
        async throws -> String?
}

public final class PasswordResetService: PasswordResetServicing {
    private let config: AuthConfiguration
    private let net: NetworkClient

    public init(config: AuthConfiguration, net: NetworkClient) {
        self.config = config
        self.net = net
    }

    public func requestReset(email: String) async throws -> String? {
        let body: [String: Any] = ["email": email]
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.requestPasswordReset,
            method: .POST,
            headers: [:],
            body: body
        )
        return env.message
    }

    public func reset(token: String, newPassword: String) async throws
        -> String?
    {
        let body: [String: Any] = ["token": token, "newPassword": newPassword]
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.resetPassword,
            method: .POST,
            headers: [:],
            body: body
        )
        return env.message
    }
}
