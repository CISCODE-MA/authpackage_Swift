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
}
