//
//  TokenFlowTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//


import XCTest
@testable import AuthPackage

final class TokenFlowTests: XCTestCase {

    func testRefreshIfNeededUpdatesAccessToken() async throws {
        let base = URL(string: "http://localhost")!
        let net = NetworkClientMock()

        // Stub refresh endpoint
        net.stub(.POST, Endpoints.refresh, with: .encodable(
            Envelope(accessToken: "new_access_123")
        ))

        let config = AuthConfiguration(baseURL: base)
        let store = InMemoryTokenStore()
        try store.save(Tokens(accessToken: "old_access", refreshToken: "refresh_abc"))

        let client = AuthClient(config: config, networkClient: net, tokenStore: store)
        try await client.refreshIfNeeded()

        XCTAssertEqual(client.accessToken, "new_access_123")
    }

    func testLogoutClearsTokenAndCallsAPI() async throws {
        let base = URL(string: "http://localhost")!
        let net = NetworkClientMock()

        net.stub(.POST, Endpoints.logout, with: .encodable(Envelope(message: "bye")))

        let config = AuthConfiguration(baseURL: base)
        let store = InMemoryTokenStore()
        try store.save(Tokens(accessToken: "some_access", refreshToken: "r"))

        let client = AuthClient(config: config, networkClient: net, tokenStore: store)
        try await client.logout()

        XCTAssertNil(client.accessToken)
    }
}
