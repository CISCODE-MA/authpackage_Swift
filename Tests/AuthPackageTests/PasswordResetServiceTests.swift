import XCTest

@testable import AuthPackage

final class PasswordResetServiceTests: XCTestCase {

    func test_request_reset_returns_message_string() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!
        )

        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.requestPasswordReset)  // "/api/auth/forgot-password"
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["email"] as? String, "u@ex.com")
            return ["message": "sent"]
        }

        let svc = PasswordResetService(config: config, net: mock)
        let message = try await svc.requestReset(email: "u@ex.com")
        XCTAssertEqual(message, "sent")
    }

    func test_reset_password_returns_message_string() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!
        )

        mock.responder = { _, path, _, _, body in
            XCTAssertEqual(path, Endpoints.resetPassword)  // "/api/auth/reset-password"
            XCTAssertEqual(body?["token"] as? String, "EMAILTOKEN")
            let pwd =
                (body?["password"] as? String)
                ?? (body?["newPassword"] as? String)
            XCTAssertEqual(pwd, "NewPass!")
            return ["message": "ok"]
        }

        let svc = PasswordResetService(config: config, net: mock)
        let msg = try await svc.reset(
            token: "EMAILTOKEN",
            newPassword: "NewPass!"
        )
        XCTAssertEqual(msg, "ok")
    }

    func test_request_reset_default_type_is_client() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!
        )

        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.requestPasswordReset)
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["type"] as? String, "client")  // default
            return ["message": "sent"]
        }

        let svc = PasswordResetService(config: config, net: mock)
        _ = try await svc.requestReset(email: "u@ex.com")
    }

    func test_resetPassword_success_message_and_payload_shape() async throws {
        let mock = MockNetworkClient()
        let cfg = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)

        var captured: [String: Any]? = nil
        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.resetPassword)
            XCTAssertEqual(method, .POST)
            captured = body
            return ["message": "reset"]
        }

        let svc = PasswordResetService(config: cfg, net: mock)
        let msg = try await svc.reset(  // <-- method name
            token: "EMAILTOKEN",
            newPassword: "NewPass123!"
        )
        XCTAssertEqual(msg, "reset")
        XCTAssertEqual(captured?["token"] as? String, "EMAILTOKEN")
    }

}
