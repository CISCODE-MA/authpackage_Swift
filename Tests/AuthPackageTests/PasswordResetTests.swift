//
//  PasswordResetTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import XCTest

@testable import AuthPackage

final class PasswordResetTests: XCTestCase {

    func testRequestAndResetPassword() async throws {
        let base = URL(string: "http://localhost")!
        let net = NetworkClientMock()
        let config = AuthConfiguration(baseURL: base)

        // Stubs
        net.stub(
            .POST,
            Endpoints.requestPasswordReset,
            with: .encodable(
                Envelope(message: "email sent", token: "reset_tkn_456")
            )
        )
        net.stub(
            .PATCH,
            Endpoints.resetPassword,
            with: .encodable(
                Envelope(message: "password updated")
            )
        )

        // Use the service directly (facade methods optional)
        let reset = PasswordResetService(config: config, net: net)
        let req = try await reset.requestReset(email: "john@example.com")
        XCTAssertEqual(req.message, "email sent")
        XCTAssertEqual(req.token, "reset_tkn_456")

        let msg = try await reset.reset(
            token: req.token ?? "",
            newPassword: "newpass"
        )
        XCTAssertEqual(msg, "password updated")
    }
}
