import XCTest
@testable import AuthPackage

final class PasswordResetServiceTests: XCTestCase {

    func test_request_reset_returns_message_string() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)

        mock.responder = { base, path, method, headers, body in
            XCTAssertEqual(path, "/api/auth/forgot-password")
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["email"] as? String, "u@ex.com")
            return ["message":"sent"]
        }

        let svc = PasswordResetService(config: config, net: mock)
        let message = try await svc.requestReset(email: "u@ex.com")
        XCTAssertEqual(message, "sent")
    }

    func test_reset_password_returns_message_string() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)

        mock.responder = { base, path, method, headers, body in
            XCTAssertEqual(path, "/api/auth/reset-password")
            _ = method
            XCTAssertEqual(body?["token"] as? String, "EMAILTOKEN")
            // accept either "password" or "newPassword"
            let pwd = (body?["password"] as? String) ?? (body?["newPassword"] as? String)
            XCTAssertEqual(pwd, "NewPass!")
            return ["message":"ok"]
        }

        let svc = PasswordResetService(config: config, net: mock)
        let msg = try await svc.reset(token: "EMAILTOKEN", newPassword: "NewPass!")
        XCTAssertEqual(msg, "ok")
    }
}
