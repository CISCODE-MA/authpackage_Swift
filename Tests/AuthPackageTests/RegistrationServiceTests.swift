import XCTest

@testable import AuthPackage

final class RegistrationServiceTests: XCTestCase {
    func test_createUser_maps_user() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!
        )

        mock.responder = { base, path, method, headers, body in
            // 🔧 Your SDK currently calls /api/auth/clients/register
            XCTAssertEqual(path, "/api/auth/clients/register")
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["email"] as? String, "vlpha@ex.com")
            XCTAssertEqual(body?["password"] as? String, "Pass123!")
            return [
                "id": "u1",
                "email": "vlpha@ex.com",
                "name": "vlpha",
                "roles": ["client"],
                "permissions": [],
            ]
        }

        let svc = RegistrationService(config: config, net: mock)
        let user = try await svc.createUser(
            email: "vlpha@ex.com",
            password: "Pass123!",
            name: "vlpha",
            roles: ["client"]
        )
        XCTAssertEqual(user.id, "u1")
        XCTAssertEqual(user.email, "vlpha@ex.com")
        XCTAssertEqual(user.name, "vlpha")
        XCTAssertEqual(user.roles, ["client"])
    }
}
