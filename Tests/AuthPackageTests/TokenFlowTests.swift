//
//  TokenFlowTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import XCTest

@testable import AuthPackage

final class TokenFlowTests: XCTestCase {

    func testLoginWithoutOTP_persistsAccess_andSetsUser() async throws {
        let net = NetworkClientMock()
        net.register(
            AuthEnvelope.self,
            path: Endpoints.login,
            method: .POST,
            value: Fixtures.envLoginNoOTP(token: Fixtures.access1)
        )
        let store = InMemoryTokenStore()
        let cfg = AuthConfiguration(baseURL: Fixtures.baseURL)
        let client = AuthClient(
            config: cfg,
            networkClient: net,
            tokenStore: store
        )

        let (sentTo, otp) = try await client.loginStart(
            identifier: "jane@example.com",
            password: "pw",
            rememberMe: true
        )
        XCTAssertNil(sentTo)
        XCTAssertNil(otp)
        XCTAssertEqual(client.currentUser?.username, Fixtures.user.username)
        XCTAssertEqual(try store.load()?.accessToken, Fixtures.access1)
    }

    func testLoginWithOTP_returnsChannel_andDoesNotPersistTokens() async throws
    {
        let net = NetworkClientMock()
        net.register(
            AuthEnvelope.self,
            path: Endpoints.login,
            method: .POST,
            value: Fixtures.envLoginOTP(otp: "000000")
        )
        let store = InMemoryTokenStore()
        let cfg = AuthConfiguration(baseURL: Fixtures.baseURL)
        let client = AuthClient(
            config: cfg,
            networkClient: net,
            tokenStore: store
        )

        let (sentTo, otp) = try await client.loginStart(
            identifier: "jane@example.com",
            password: "pw",
            rememberMe: true
        )
        XCTAssertEqual(sentTo, Fixtures.user.email)
        XCTAssertEqual(otp, "000000")
        XCTAssertNil(try store.load()?.accessToken)
        XCTAssertNil(client.currentUser)
    }

    func testVerifyOTP_persistsAccess_andSetsUser() async throws {
        let net = NetworkClientMock()
        net.register(
            AuthEnvelope.self,
            path: Endpoints.verifyOTP,
            method: .POST,
            value: Fixtures.envVerifyOTP(token: Fixtures.access1)
        )
        let store = InMemoryTokenStore()
        let cfg = AuthConfiguration(baseURL: Fixtures.baseURL)

        // OTPService persists on verify internally; AuthClient exposes the flow
        let client = AuthClient(
            config: cfg,
            networkClient: net,
            tokenStore: store
        )
        _ = try await client.verifyOTP(
            identifier: "jane@example.com",
            otp: "000000"
        )
        XCTAssertEqual(try store.load()?.accessToken, Fixtures.access1)
        XCTAssertEqual(client.currentUser?.email, Fixtures.user.email)
    }

    func testRefresh_usesCookieEndpoint_andPersistsNewAccess() async throws {
        let net = NetworkClientMock()
        net.register(
            AuthEnvelope.self,
            path: Endpoints.refresh,
            method: .POST,
            value: Fixtures.envRefresh(token: Fixtures.access2)
        )
        let store = InMemoryTokenStore()
        try store.save(Tokens(accessToken: Fixtures.access1))
        let cfg = AuthConfiguration(baseURL: Fixtures.baseURL)
        let client = AuthClient(
            config: cfg,
            networkClient: net,
            tokenStore: store
        )

        try await client.refreshIfNeeded()
        XCTAssertEqual(try store.load()?.accessToken, Fixtures.access2)
    }

    func testLogout_callsAPI_andClearsStore() async throws {
        let net = NetworkClientMock()
        net.register(
            AuthEnvelope.self,
            path: Endpoints.logout,
            method: .POST,
            value: .init(
                message: "bye",
                user: nil,
                otpCode: nil,
                rememberMe: nil,
                accessToken: nil,
                token: nil
            )
        )
        let store = InMemoryTokenStore()
        try store.save(Tokens(accessToken: Fixtures.access1))
        let cfg = AuthConfiguration(baseURL: Fixtures.baseURL)
        let client = AuthClient(
            config: cfg,
            networkClient: net,
            tokenStore: store
        )

        try await client.logout()
        XCTAssertNil(try store.load())
        XCTAssertNil(client.currentUser)
    }
}
