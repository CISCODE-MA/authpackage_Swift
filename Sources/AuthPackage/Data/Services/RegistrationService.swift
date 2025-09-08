//
//  RegistrationService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol RegistrationServicing {
    func register(
        fname: String, lname: String, username: String, email: String,
        phone: String, password: String, roles: [String]
    ) async throws -> (message: String?, user: User?, emailToken: String?)

    func verifyEmail(token: String)
        async throws -> (message: String?, user: User?)
}

public final class RegistrationService: RegistrationServicing {
    private let config: AuthConfiguration
    private let net: NetworkClient

    public init(config: AuthConfiguration, net: NetworkClient) {
        self.config = config
        self.net = net
    }

    public func register(
        fname: String, lname: String, username: String, email: String,
        phone: String, password: String, roles: [String]
    ) async throws -> (message: String?, user: User?, emailToken: String?) {
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.register,
            method: .POST,
            headers: [:],
            body: [
                "fullname": ["fname": fname, "lname": lname],
                "username": username,
                "email": email,
                "phoneNumber": phone,
                "password": password,
                "roles": roles,
            ]
        )
        return (
            message: env.message, user: env.user.map(Mapper.user),
            emailToken: env.token
        )
    }

    public func verifyEmail(token: String)
        async throws -> (message: String?, user: User?)
    {
        let path = "\(Endpoints.verifyEmail)?token=\(token)"
        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: path,
            method: .GET,
            headers: [:],
            body: nil
        )
        return (message: env.message, user: env.user.map(Mapper.user))
    }
}
