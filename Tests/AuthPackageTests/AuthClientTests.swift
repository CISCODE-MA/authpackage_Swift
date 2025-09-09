//
//  AuthClientTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import XCTest

@testable import AuthPackage

final class AuthClientTests: XCTestCase {
    func testAccessTokenComputedPropertyReadsStore() throws {
        let store = InMemoryTokenStore()
        try store.save(Tokens(accessToken: "A"))
        let net = NetworkClientMock()
        let client = AuthClient(
            config: .init(baseURL: Fixtures.baseURL),
            networkClient: net,
            tokenStore: store
        )
        XCTAssertEqual(client.accessToken, "A")
    }
}
