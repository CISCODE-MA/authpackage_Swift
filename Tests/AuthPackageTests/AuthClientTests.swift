//
//  AuthClientTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 16/09/2025.
//

import XCTest

@testable import AuthPackage

final class AuthClientTests: XCTestCase {

    func test_login_returns_claims_when_accessToken_present_and_stores_tokens()
        async throws
    {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()

        // Minimal unsigned JWT; body decodable by your JWT decoder.
        let jwt =
            "eyJhbGciOiJub25lIn0.eyJzdWIiOiJ1c2VyMSIsImVtYWlsIjoidUBleC5jb20ifQ."
        mock.responder = { _, path, _, _, _ in
            XCTAssertEqual(path, Endpoints.login)
            return ["accessToken": jwt, "refreshToken": "RT"]
        }

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: store
        )
        let claims = try await client.login(email: "u@ex.com", password: "pw")
        XCTAssertNotNil(claims)
        XCTAssertEqual(try store.load()?.refreshToken, "RT")
    }

    func test_refreshIfNeeded_delegates_to_TokenService() async throws {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        mock.responder = { _, path, _, _, _ in
            if path == Endpoints.refresh { return ["accessToken": "NEW"] }
            return [:]
        }

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: InMemoryTokenStore()
        )
        let access = try await client.refreshIfNeeded()
        XCTAssertEqual(access, "NEW")
    }

    func test_logout_clears_token_store() async throws {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()
        try store.save(.init(accessToken: "A", refreshToken: "R", expiry: nil))

        mock.responder = { _, path, _, _, _ in
            if path == Endpoints.logout { return ["message": "bye"] }
            return [:]
        }

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: store
        )
        try await client.logout()
        XCTAssertNil(try store.load())
    }

    func
        test_refreshIfNeeded_returns_cached_when_not_expired_and_no_network_call()
        async throws
    {
        let mock = MockNetworkClient()
        mock.responder = { _, _, _, _, _ in
            XCTFail("Network must NOT be called when token is fresh")
            return [:]
        }
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()
        try store.save(
            .init(
                accessToken: "CACHED",
                refreshToken: "R",
                expiry: Date().addingTimeInterval(3600)
            )
        )

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: store
        )
        let token = try await client.refreshIfNeeded()
        XCTAssertEqual(token, "CACHED")
    }

    func test_login_propagates_error_and_does_not_save_tokens() async {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()

        mock.responder = { _, _, _, _, _ in throw APIError.network("boom") }

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: store
        )
        do {
            _ = try await client.login(email: "u@ex.com", password: "pw")
            XCTFail("Expected error")
        } catch { /* ok */  }
        XCTAssertNil(try? store.load())
    }

}
