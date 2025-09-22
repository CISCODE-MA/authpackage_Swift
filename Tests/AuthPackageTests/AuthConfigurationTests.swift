//
//  AuthConfigurationTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 16/09/2025.
//

import XCTest

@testable import AuthPackage

final class AuthConfigurationTests: XCTestCase {
    func test_init_sets_fields() {
        let base = URL(string: "http://unit.test")!
        let cfg = AuthConfiguration(
            baseURL: base,
            refreshUsesCookie: true,
            redirectScheme: "authdemo",
            microsoftEnabled: true
        )
        XCTAssertEqual(cfg.baseURL, base)
        XCTAssertTrue(cfg.refreshUsesCookie)
        XCTAssertEqual(cfg.redirectScheme, "authdemo")
        XCTAssertTrue(cfg.microsoftEnabled)
    }

    func test_defaults_are_correct() {
        let base = URL(string: "http://unit.test")!
        let cfg = AuthConfiguration(baseURL: base)
        XCTAssertEqual(cfg.baseURL, base)
        XCTAssertTrue(cfg.refreshUsesCookie)
        XCTAssertNil(cfg.redirectScheme)
        XCTAssertFalse(cfg.microsoftEnabled)
        XCTAssertFalse(cfg.googleEnabled)
        XCTAssertFalse(cfg.facebookEnabled)
        XCTAssertTrue(cfg.ephemeralWebSession)
    }

    func test_microsoftConfig_defaults_and_fields() {
        let m = MicrosoftConfig(
            tenant: "common",
            clientID: "client",
            redirectScheme: "authdemo",
            redirectURI: "authdemo://cb"
                // rely on defaults for enabled/scopes/useBuiltInWebOAuth/microsoftEnabled
        )
        XCTAssertTrue(m.enabled)  // default true
        XCTAssertEqual(m.tenant, "common")
        XCTAssertEqual(m.clientID, "client")
        XCTAssertEqual(m.redirectScheme, "authdemo")
        XCTAssertEqual(m.redirectURI, "authdemo://cb")
        XCTAssertEqual(
            m.scopes,
            ["openid", "email", "profile", "offline_access"]
        )  // default
        XCTAssertTrue(m.useBuiltInWebOAuth)  // default true
        XCTAssertTrue(m.microsoftEnabled)  // default true
    }


}
