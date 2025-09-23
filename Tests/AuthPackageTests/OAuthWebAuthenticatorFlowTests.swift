//
//  OAuthWebAuthenticatorFlowTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 22/09/2025.
//

import AuthenticationServices
import XCTest

@testable import AuthPackage

// MARK: - Test doubles

private final class FakeSession: WebAuthSession {
    var prefersEphemeralWebBrowserSession = false
    var started = false
    var onStart: (() -> Void)?
    func start() -> Bool {
        started = true
        onStart?()
        return true
    }
    func cancel() {}
}

private final class CapturingFactory: WebAuthSessionFactory {
    let session = FakeSession()
    var lastURL: URL?
    var lastScheme: String?
    var completion: ((URL?, Error?) -> Void)?

    func make(
        url: URL,
        callbackURLScheme: String,
        provider: ASWebAuthenticationPresentationContextProviding,
        completion: @escaping (URL?, Error?) -> Void
    ) -> WebAuthSession {
        lastURL = url
        lastScheme = callbackURLScheme
        self.completion = completion
        return session
    }
}

// MARK: - Flows

@MainActor
final class OAuthWebAuthenticatorFlowTests: XCTestCase {

    func test_success_path_saves_and_returns_tokens_and_sets_ephemeral()
        async throws
    {
        // Arrange
        let store = InMemoryTokenStore()
        let cfg = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!,
            redirectScheme: "authdemo",
            ephemeralWebSession: true
        )
        let factory = CapturingFactory()
        let sut = OAuthWebAuthenticator(
            config: cfg,
            tokenStore: store,
            sessionFactory: factory
        )

        // Simulate Safari callback when the session starts
        factory.session.onStart = {
            let cb = URL(
                string:
                    "authdemo://auth/callback?accessToken=ACC&refreshToken=REF"
            )!
            factory.completion?(cb, nil)
        }

        // Act
        let tokens = try await sut.signInMicrosoft(from: ASPresentationAnchor())

        // Assert
        XCTAssertEqual(tokens.accessToken, "ACC")
        XCTAssertEqual(tokens.refreshToken, "REF")
        XCTAssertEqual(try store.load(), tokens)  // persisted
        XCTAssertEqual(factory.lastScheme, "authdemo")  // scheme used
        XCTAssertTrue(factory.session.prefersEphemeralWebBrowserSession)  // flag propagated
        XCTAssertTrue(factory.session.started)  // session started
    }

    @MainActor
    func test_success_without_refreshToken_saves_nil_refresh() async throws {
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!,
                                    redirectScheme: "authdemo",
                                    ephemeralWebSession: true)

        let store = InMemoryTokenStore()
        let factory = CapturingFactory()
        let sut = OAuthWebAuthenticator(config: cfg, tokenStore: store, sessionFactory: factory)

        // Drive success: only accessToken present
        factory.session.onStart = {
            let url = URL(string: "authdemo://auth/callback?accessToken=AAA")!
            factory.completion?(url, nil)
        }

        let tokens = try await sut.signInMicrosoft(from: ASPresentationAnchor())
        XCTAssertEqual(tokens.accessToken, "AAA")
        XCTAssertNil(tokens.refreshToken)
        XCTAssertEqual(try store.load()?.refreshToken, nil)
    }

    
    func test_missing_accessToken_maps_to_unauthorized_and_does_not_save() async
    {
        let store = InMemoryTokenStore()
        let cfg = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!,
            redirectScheme: "authdemo"
        )
        let factory = CapturingFactory()
        let sut = OAuthWebAuthenticator(
            config: cfg,
            tokenStore: store,
            sessionFactory: factory
        )

        factory.session.onStart = {
            // No accessToken in callback
            let cb = URL(string: "authdemo://auth/callback?foo=bar")!
            factory.completion?(cb, nil)
        }

        do {
            _ = try await sut.signInMicrosoft(from: ASPresentationAnchor())
            XCTFail("Expected unauthorized")
        } catch APIError.unauthorized { /* ok */  } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertNil(try? store.load())
    }

    func test_canceled_login_maps_to_unauthorized() async {
        let cfg = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!,
            redirectScheme: "authdemo"
        )
        let factory = CapturingFactory()
        let sut = OAuthWebAuthenticator(
            config: cfg,
            tokenStore: InMemoryTokenStore(),
            sessionFactory: factory
        )

        factory.session.onStart = {
            let err = NSError(
                domain: ASWebAuthenticationSessionErrorDomain,
                code: ASWebAuthenticationSessionError.Code.canceledLogin
                    .rawValue,
                userInfo: nil
            )
            factory.completion?(nil, err)
        }

        do {
            _ = try await sut.signInMicrosoft(from: ASPresentationAnchor())
            XCTFail("Expected unauthorized")
        } catch APIError.unauthorized { /* ok */  } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    @MainActor
    func test_generic_error_maps_to_unauthorized() async {
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!,
                                    redirectScheme: "authdemo")
        let factory = CapturingFactory()
        let sut = OAuthWebAuthenticator(config: cfg,
                                        tokenStore: InMemoryTokenStore(),
                                        sessionFactory: factory)

        factory.session.onStart = {
            factory.completion?(nil, NSError(domain: "test", code: -1))
        }

        do {
            _ = try await sut.signInMicrosoft(from: ASPresentationAnchor())
            XCTFail("Expected unauthorized")
        } catch APIError.unauthorized {
            // current production behavior
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_presentationAnchor_fallback_when_no_anchor_set() {
        // Covers the tiny else-branch returning a new ASPresentationAnchor
        let sut = OAuthWebAuthenticator(
            config: AuthConfiguration(
                baseURL: URL(string: "http://unit.test")!
            ),
            tokenStore: InMemoryTokenStore()
        )
        let dummy = ASWebAuthenticationSession(
            url: URL(string: "http://example.com")!,
            callbackURLScheme: "x",
            completionHandler: { _, _ in }
        )
        _ = sut.presentationAnchor(for: dummy)  // no crash = covered
    }
}
