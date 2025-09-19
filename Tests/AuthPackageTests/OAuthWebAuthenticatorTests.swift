//
//  OAuthWebAuthenticatorTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 19/09/2025.
//

import XCTest
import AuthenticationServices
@testable import AuthPackage

final class OAuthWebAuthenticatorTests: XCTestCase {

    func test_signInMicrosoft_throws_when_redirectScheme_is_nil() async {
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!,
                                    redirectScheme: nil)
        let sut = await OAuthWebAuthenticator(config: cfg, tokenStore: InMemoryTokenStore())

        do {
            _ = try await sut.signInMicrosoft(from: ASPresentationAnchor())
            XCTFail("Expected APIError.invalidURL")
        } catch APIError.invalidURL {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_signInMicrosoft_throws_when_redirectScheme_is_empty() async {
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!,
                                    redirectScheme: "")
        let sut = await OAuthWebAuthenticator(config: cfg, tokenStore: InMemoryTokenStore())

        do {
            _ = try await sut.signInMicrosoft(from: ASPresentationAnchor())
            XCTFail("Expected APIError.invalidURL")
        } catch APIError.invalidURL {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
