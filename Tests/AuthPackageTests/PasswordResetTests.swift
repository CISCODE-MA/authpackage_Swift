//
//  PasswordResetTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import XCTest

@testable import AuthPackage

final class PasswordResetTests: XCTestCase {
    func testRequestReset_thenReset() async throws {
        let net = NetworkClientMock()
        net.register(
            AuthEnvelope.self,
            path: Endpoints.requestPasswordReset,
            method: .POST,
            value: .init(
                message: "email-sent",
                user: nil,
                otpCode: nil,
                rememberMe: nil,
                accessToken: nil,
                token: "reset-token"
            )
        )
        net.register(
            AuthEnvelope.self,
            path: Endpoints.resetPassword,
            method: .PATCH,
            value: .init(
                message: "reset-ok",
                user: nil,
                otpCode: nil,
                rememberMe: nil,
                accessToken: nil,
                token: nil
            )
        )

        let cfg = AuthConfiguration(baseURL: Fixtures.baseURL)
        let client = AuthClient(
            config: cfg,
            networkClient: net,
            tokenStore: InMemoryTokenStore()
        )

        try await client.requestPasswordReset(email: "jane@example.com")
        try await client.resetPassword(
            token: "reset-token",
            newPassword: "newpw"
        )
    }
}
