import XCTest
@testable import AuthPackage

final class TokenServiceTests: XCTestCase {

    func test_refresh_returns_new_access_token() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let tokens = InMemoryTokenStore()

        mock.responder = { base, path, method, headers, body in
            XCTAssertEqual(path, "/api/auth/refresh-token")
            _ = method // accept GET/POST variations
            return ["accessToken": "NEW"]
        }

        let svc = TokenService(config: config, net: mock, tokens: tokens)
        let newAccess = try await svc.refresh(refreshToken: "old-refresh")
        XCTAssertEqual(newAccess, "NEW")
        XCTAssertEqual(try tokens.load()?.accessToken, "NEW")
    }

    func test_logout_clears_store() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let tokens = InMemoryTokenStore()
        try tokens.save(.init(accessToken: "A", refreshToken: "R", expiry: nil))

        mock.responder = { base, path, method, headers, body in
            XCTAssertEqual(path, "/api/auth/logout")
            return ["message": "bye"]
        }

        let svc = TokenService(config: config, net: mock, tokens: tokens)
        _ = try await svc.logout()
        XCTAssertNil(try tokens.load())
    }
}
