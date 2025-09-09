//
//  RegistrationTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import XCTest

@testable import AuthPackage

final class RegistrationTests: XCTestCase {
    func testRegister_andVerifyEmail() async throws {
        let net = NetworkClientMock()
        // register → returns user + token (email verify token)
        net.register(
            AuthEnvelope.self,
            path: Endpoints.register,
            method: .POST,
            value: .init(
                message: "reg-ok",
                user: Fixtures.dtoUser,
                otpCode: nil,
                rememberMe: nil,
                accessToken: nil,
                token: "email-token"
            )
        )
        // verify-email GET
        net.register(
            AuthEnvelope.self,
            path: "\(Endpoints.verifyEmail)?token=email-token",
            method: .GET,
            value: .init(
                message: "verified",
                user: Fixtures.dtoUser,
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

        let user = try await client.register(
            fname: "Jane",
            lname: "Doe",
            username: "jane",
            email: "jane@example.com",
            phone: "",
            password: "pw",
            roles: ["user"]
        )
        XCTAssertEqual(user?.email, Fixtures.user.email)

        try await client.verifyEmail(token: "email-token")  // simple smoke test
    }
}
