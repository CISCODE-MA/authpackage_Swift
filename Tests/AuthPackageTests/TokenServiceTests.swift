import XCTest
@testable import AuthPackage

final class TokenServiceTests: XCTestCase {

    func test_refresh_returns_new_access_token_and_updates_store() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let tokens = InMemoryTokenStore()

        mock.responder = { _, path, _, _, _ in
            XCTAssertEqual(path, Endpoints.refresh) // "/api/auth/refresh-token"
            return ["accessToken": "NEW"]
        }

        let svc = TokenService(config: config, net: mock, tokens: tokens)
        let newAccess = try await svc.refresh(refreshToken: "old-refresh")
        XCTAssertEqual(newAccess, "NEW")
        XCTAssertEqual(try tokens.load()?.accessToken, "NEW")
    }

    func test_refresh_uses_cookie_when_no_refreshToken_and_store_empty() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()

        var capturedBody: [String:Any]? = ["_": "should be nil"]
        mock.responder = { _, path, _, _, body in
            XCTAssertEqual(path, Endpoints.refresh)
            capturedBody = body
            return ["accessToken":"NEW"]
        }

        let svc = TokenService(config: config, net: mock, tokens: store)
        _ = try await svc.refresh(refreshToken: nil)
        XCTAssertNil(capturedBody, "Cookie refresh should send no body")
    }

    func test_refresh_preserves_existing_refreshToken_in_store() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()
        try store.save(.init(accessToken: "OLD", refreshToken: "KEEP", expiry: nil))

        mock.responder = { _, path, _, _, _ in
            XCTAssertEqual(path, Endpoints.refresh)
            return ["accessToken":"NEW"]
        }

        let svc = TokenService(config: config, net: mock, tokens: store)
        _ = try await svc.refresh(refreshToken: nil)
        let saved = try store.load()
        XCTAssertEqual(saved?.accessToken, "NEW")
        XCTAssertEqual(saved?.refreshToken, "KEEP")
    }

    func test_logout_clears_store() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let tokens = InMemoryTokenStore()
        try tokens.save(.init(accessToken: "A", refreshToken: "R", expiry: nil))

        mock.responder = { _, path, _, _, _ in
            XCTAssertEqual(path, Endpoints.logout) // "/api/auth/logout"
            return ["message": "bye"]
        }

        let svc = TokenService(config: config, net: mock, tokens: tokens)
        _ = try await svc.logout()
        XCTAssertNil(try tokens.load())
    }
}
