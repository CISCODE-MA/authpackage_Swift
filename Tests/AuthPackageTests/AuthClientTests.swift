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
        let cfg = AuthConfiguration(
            baseURL: URL(string: "http://localhost:3000")!)
        let net = NetworkClientMock()
        let tokens = InMemoryTokenStore()
        let client = AuthClient(
            config: cfg, networkClient: net, tokenStore: tokens)

        // 1) login start returns otp prompt
        net.stub = AuthEnvelope(
            message: "OTP sent",
            user: UserDTO(
                id: "1", fullname: nil, username: "u", email: "e@x.com",
                phoneNumber: nil, roles: []), otpCode: "123456",
            rememberMe: true, accessToken: nil, token: nil)
        let (email, otp) = try await client.loginStart(
            identifier: "e@x.com", password: "pw", rememberMe: true)
        XCTAssertEqual(email, "e@x.com")
        XCTAssertEqual(otp, "123456")

        // 2) verify otp returns access token
        net.stub = AuthEnvelope(
            message: "OK",
            user: UserDTO(
                id: "1", fullname: nil, username: "u", email: "e@x.com",
                phoneNumber: nil, roles: []), otpCode: nil, rememberMe: nil,
            accessToken: "access123", token: nil)
        let user = try await client.verifyOTP(
            identifier: "e@x.com", otp: "123456")
        XCTAssertEqual(user.email, "e@x.com")
        XCTAssertEqual(client.accessToken, "access123")
    }
}
