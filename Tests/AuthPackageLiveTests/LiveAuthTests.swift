//
//  LiveAuthTests.swift
//  AuthPackageLiveTests
//  Optional integration tests hitting a real backend.
//

import XCTest
@testable import AuthPackage

final class LiveAuthTests: XCTestCase {
    private var base: URL!
    private var email: String!
    private var password: String!
    private var tenant: String!

    override func setUp() {
        super.setUp()
        guard let baseUrl = ProcessInfo.processInfo.environment["LIVE_BASE_URL"],
              let url = URL(string: baseUrl) else {
            throw XCTSkip("LIVE_BASE_URL not set — skipping live tests")
        }
        base = url
        email = ProcessInfo.processInfo.environment["LIVE_EMAIL"] ?? "a@b.com"
        password = ProcessInfo.processInfo.environment["LIVE_PASSWORD"] ?? "Secret123!"
        tenant = ProcessInfo.processInfo.environment["LIVE_TENANT"] ?? "t-001"
    }

    func testLive_Login_Refresh_Logout() async throws {
        let client = AuthClient(config: AuthConfiguration(baseURL: base), tokenStore: InMemoryTokenStore())
        let claims = try await client.login(email: email, password: password, tenantId: tenant)
        XCTAssertNotNil(claims)

        let refreshed = try await client.refreshIfNeeded()
        XCTAssertNotNil(refreshed)

        try await client.logout()
    }
}
