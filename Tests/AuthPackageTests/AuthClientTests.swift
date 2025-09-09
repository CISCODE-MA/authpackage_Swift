//
//  AuthClientTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import XCTest

@testable import AuthPackage

final class AuthClientTests: XCTestCase {
    func testLoginFlow() async throws {
        let base = URL(string: "http://localhost")!
        let net = NetworkClientMock()
        let config = AuthConfiguration(baseURL: base)
        let store = InMemoryTokenStore()
        let client = AuthClient(
            config: config,
            networkClient: net,
            tokenStore: store
        )

        let user = UserDTO.fixture()

        // login
        net.stub(
            .POST,
            Endpoints.login,
            with: .encodable(
                Envelope(
                    message: "OTP sent",
                    otpCode: "123456",
                    rememberMe: true,
                    user: user
                )
            )
        )
        // verify
        net.stub(
            .POST,
            Endpoints.verifyOTP,
            with: .encodable(
                Envelope(message: "OK", accessToken: "acc_123", user: user)
            )
        )

        let (otpSentTo, debugOTP) = try await client.loginStart(
            identifier: "john@example.com",
            password: "pw",
            rememberMe: true
        )
        XCTAssertEqual(otpSentTo, "john@example.com")
        XCTAssertEqual(debugOTP, "123456")

        let loggedIn = try await client.verifyOTP(
            identifier: "john@example.com",
            otp: "123456"
        )
        XCTAssertEqual(loggedIn.email, "john@example.com")
        XCTAssertEqual(client.accessToken, "acc_123")
    }
}
