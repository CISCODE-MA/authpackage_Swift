//
//  RegistrationTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import XCTest

@testable import AuthPackage

final class RegistrationTests: XCTestCase {

    func testRegisterAndVerifyEmail() async throws {
        let base = URL(string: "http://localhost")!
        let net = NetworkClientMock()

        // Use a single source of truth for the email under test
        let expectedEmail = "john@example.com"
        var user = UserDTO.fixture(email: expectedEmail)  // ensure stubbed user matches

        // Stub register -> returns user + email token
        net.stub(
            .POST,
            Endpoints.register,
            with: .encodable(
                Envelope(message: "ok", token: "email_tkn_123", user: user)
            )
        )
        // Stub verify email -> returns same user
        net.stub(
            .GET,
            "\(Endpoints.verifyEmail)?token=email_tkn_123",
            with: .encodable(
                Envelope(message: "verified", user: user)
            )
        )

        let config = AuthConfiguration(baseURL: base)
        let store = InMemoryTokenStore()
        let client = AuthClient(
            config: config,
            networkClient: net,
            tokenStore: store
        )

        // register
        let u = try await client.register(
            fname: "John",
            lname: "Doe",
            username: "johndoe",
            email: expectedEmail,
            phone: "+123456789",
            password: "pw",
            roles: ["user"]
        )

        // Normalize case to avoid case-sensitivity flakes
        XCTAssertEqual(u?.email.lowercased(), expectedEmail.lowercased())

        // verify
        try await client.verifyEmail(token: "email_tkn_123")
    }
}
