//
//  LoginService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol LoginServicing {
    func login(identifier: String, password: String, rememberMe: Bool)
        async throws -> (
            message: String?, user: User?, otpCode: String?, rememberMe: Bool?
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
            message: String?, user: User?, otpCode: String?, rememberMe: Bool?
        )
    {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.login,
            method: .POST,
            headers: [:],
            body: [
                "identifier": identifier, "password": password,
                "rememberMe": rememberMe,
            ]
        )
        return (
            message: env.message,
            user: env.user.map(Mapper.user),
            otpCode: env.otpCode,
            rememberMe: env.rememberMe
        )
    }
}
