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
        tenantId: String?,
        roles: [String]?
    ) async throws -> User
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

    public func createUser(
        email: String,
        password: String,
        name: String?,
        tenantId: String?,
        roles: [String]?
    ) async throws -> User {
        var body: [String: Any] = [
            "email": email, "password": password, "tenantId": tenantId ?? "",
        ]
        if let name { body["name"] = name }
        if let roles { body["roles"] = roles }

        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.registerUser,  // POST /api/users
            method: .POST,
            headers: [:],
            body: body
        )
        guard let dto = env.user else { throw APIError.unknown }
        return Mapper.user(dto)
    }

    public func inviteUser(email: String, name: String?, tenantId: String)
        async throws -> String?
    {
        var body: [String: Any] = ["email": email, "tenantId": tenantId]
        if let name { body["name"] = name }

        let env: AuthEnvelope = try await net.send(
            baseURL: config.baseURL,
            path: Endpoints.inviteUser,  // POST /api/users/invite
            method: .POST,
            headers: [:],
            body: body
        )
        return env.message
    }

}
