//
//  PasswordResetService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol PasswordResetServicing {
    func requestReset(email: String) async throws -> (
        message: String?, token: String?
    )
    func reset(token: String, newPassword: String) async throws -> (
        message: String?
    )
}

public final class PasswordResetService: PasswordResetServicing {
    private let config: AuthConfiguration
    private let net: NetworkClient

    public init(config: AuthConfiguration, net: NetworkClient) {
        self.config = config
        self.net = net
    }

    public func requestReset(email: String) async throws -> (String?, String?) {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL, path: Endpoints.requestPasswordRest,
            method: .POST, headers: [:], body: ["email": email])
        return (env.message, env.token)
    }

    public func reset(token: String, newPassword: String) async throws -> (
        String?
    ) {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL, path: Endpoints.resetPassword,
            method: .PATCH, headers: [:],
            body: [
                "token": token, "newPassword": newPassword,
                "confirmNewPassword": newPassword,
            ])
        return env.message
    }
}
