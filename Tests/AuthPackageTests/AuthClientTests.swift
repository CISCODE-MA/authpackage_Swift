//
//  AuthClientTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 16/09/2025.
//

import XCTest
import AuthenticationServices


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
        test_refreshIfNeeded_refreshes_even_with_existing_token_and_updates_store()
        async throws
    {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()
        try store.save(
            .init(
                accessToken: "OLD",
                refreshToken: "R",
                expiry: Date().addingTimeInterval(3600)
            )
        )

        mock.responder = { _, path, _, _, _ in
            XCTAssertEqual(path, Endpoints.refresh)  // should delegate to /refresh-token
            return ["accessToken": "NEW"]
        }

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: store
        )
        let access = try await client.refreshIfNeeded()
        XCTAssertEqual(access, "NEW")
        XCTAssertEqual(try store.load()?.accessToken, "NEW")
        XCTAssertEqual(try store.load()?.refreshToken, "R")
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

    func test_register_delegates_to_registrationService() async throws {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)

        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.registerClient)
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["email"] as? String, "z@ex.com")
            return [
                "id": "u9", "email": "z@ex.com", "name": "Z",
                "roles": ["client"], "permissions": [],
            ]
        }

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: InMemoryTokenStore()
        )
        let user = try await client.register(
            email: "z@ex.com",
            password: "pw",
            name: "Z",
            roles: ["client"]
        )
        XCTAssertEqual(user.id, "u9")
    }

    func test_requestPasswordReset_delegates_to_service() async throws {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)

        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.requestPasswordReset)
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["email"] as? String, "u@ex.com")
            return ["message": "sent"]
        }

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: InMemoryTokenStore()
        )
        let msg = try await client.requestPasswordReset(
            email: "u@ex.com",
            type: "client"
        )
        XCTAssertEqual(msg, "sent")
    }

    func test_resetPassword_delegates_to_service() async throws {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)

        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.resetPassword)
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["token"] as? String, "T")
            return ["message": "ok"]
        }

        let client = AuthClient(
            config: cfg,
            networkClient: mock,
            tokenStore: InMemoryTokenStore()
        )
        let msg = try await client.resetPassword(token: "T", newPassword: "New")
        XCTAssertEqual(msg, "ok")
    }

    @MainActor
    func test_loginWithMicrosoft_throws_when_feature_disabled() async {
        let cfg = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!,
            microsoftEnabled: false
        )
        let client = AuthClient(
            config: cfg,
            networkClient: MockNetworkClient(),
            tokenStore: InMemoryTokenStore()
        )
        do {
            _ = try await client.loginWithMicrosoft(
                from: ASPresentationAnchor()
            )
            XCTFail("Expected error")
        } catch { /* ok: guarded by feature flag */  }
    }

    @MainActor
    func test_loginWithGoogle_throws_when_feature_disabled() async {
        let cfg = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!,
            googleEnabled: false
        )
        let client = AuthClient(
            config: cfg,
            networkClient: MockNetworkClient(),
            tokenStore: InMemoryTokenStore()
        )
        do {
            _ = try await client.loginWithGoogle(from: ASPresentationAnchor())
            XCTFail("Expected error")
        } catch {}
    }

    @MainActor
    func test_loginWithFacebook_throws_when_feature_disabled() async {
        let cfg = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!,
            facebookEnabled: false
        )
        let client = AuthClient(
            config: cfg,
            networkClient: MockNetworkClient(),
            tokenStore: InMemoryTokenStore()
        )
        do {
            _ = try await client.loginWithFacebook(from: ASPresentationAnchor())
            XCTFail("Expected error")
        } catch {}
    }

}
