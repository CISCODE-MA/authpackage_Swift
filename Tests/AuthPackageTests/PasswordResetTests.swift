import XCTest
@testable import AuthPackage

final class PasswordResetTests: XCTestCase {

    func testRequestAndResetPassword() async throws {
        let base = URL(string: "http://localhost")!
        let net = NetworkClientMock()

        net.stub(.POST, Endpoints.requestPasswordReset, with: .encodable(
            Envelope(message: "email sent", token: "reset_tkn_456")
        ))
        net.stub(.PATCH, Endpoints.resetPassword, with: .encodable(
            Envelope(message: "password updated")
        ))

        let config = AuthConfiguration(baseURL: base)
        let client = AuthClient(config: config, networkClient: net, tokenStore: InMemoryTokenStore())

        // Normally you'd expose wrappers; here we drive services by facade calls if present.
        // If the facade doesn't expose these yet, test services directly.

        // Direct service test (if needed):
        let reset = PasswordResetService(config: config, net: net)
        let req = try await reset.requestReset(email: "john@example.com")
        XCTAssertEqual(req.message, "email sent")
        XCTAssertEqual(req.token, "reset_tkn_456")

        let msg = try await reset.reset(token: req.token ?? "", newPassword: "newpass")
        XCTAssertEqual(msg, "password updated")
    }
}
