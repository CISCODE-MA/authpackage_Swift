//
//  RegistrationService.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol RegistrationServicing {
    func createUser(
        email: String,
        password: String,
        name: String?,
        roles: [String]?
    ) async throws -> User

    // If you keep invites via /api/users/invite, leave this. Otherwise remove it.
    func inviteUser(email: String, name: String?, tenantId: String) async throws
        -> String?
}

public final class RegistrationService: RegistrationServicing {
    private let config: AuthConfiguration
    private let net: NetworkClient

    public init(config: AuthConfiguration, net: NetworkClient) {
        self.config = config
        self.net = net
    }

    // POST /api/clients/register
    public func createUser(
        email: String,
        password: String,
        name: String?,
        roles: [String]?
    ) async throws -> User {
        var body: [String: Any] = [
            "email": email,
            "password": password,
        ]
        if let name, !name.isEmpty { body["name"] = name }
        if let roles, !roles.isEmpty { body["roles"] = roles }

        let resp: ClientRegistrationResponse = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.registerClient,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: body
        )
        return Mapper.user(from: resp)
    }

    // Optional legacy admin flow
    public func inviteUser(email: String, name: String?, tenantId: String)
        async throws -> String?
    {
        var body: [String: Any] = ["email": email, "tenantId": tenantId]
        if let name, !name.isEmpty { body["name"] = name }

        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.inviteUser,  // keep only if you have this route
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: body
        )
        return env.message
    }
}
