//
//  ProfileRulesTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 06/10/2025.
//

import XCTest

@testable import AuthPackage

final class ProfileRulesTests: XCTestCase {

    func test_username_rule_pass() {
        XCTAssertNil(ProfileRules.validateUsername("Jane"))
        XCTAssertNil(ProfileRules.validateUsername("  John  "))
    }

    func test_username_rule_fail() {
        XCTAssertNotNil(ProfileRules.validateUsername(""))
        XCTAssertNotNil(ProfileRules.validateUsername(" "))
        XCTAssertNotNil(ProfileRules.validateUsername("a"))
    }

    func test_email_rule_pass() {
        XCTAssertNil(ProfileRules.validateEmail("me@domain.com"))
        XCTAssertNil(ProfileRules.validateEmail("ME+alias@EXAMPLE.io"))
    }

    func test_email_rule_fail() {
        XCTAssertNotNil(ProfileRules.validateEmail("me"))
        XCTAssertNotNil(ProfileRules.validateEmail("me@"))
        XCTAssertNotNil(ProfileRules.validateEmail("@domain.com"))
        XCTAssertNotNil(ProfileRules.validateEmail("me@domain"))
    }
}
