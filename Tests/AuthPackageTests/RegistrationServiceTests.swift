import XCTest

@testable import AuthPackage

final class RegistrationServiceTests: XCTestCase {
    func test_createUser_maps_user() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!
        )

        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.registerClient)  // "/api/auth/clients/register"
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

    func test_createUser_omits_optional_fields_when_nil_or_empty() async throws
    {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!
        )

        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.registerClient)
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["email"] as? String, "opt@ex.com")
            XCTAssertEqual(body?["password"] as? String, "P@ssw0rd")
            XCTAssertNil(body?["name"])
            XCTAssertNil(body?["roles"])
            return [
                "id": "u2",
                "email": "opt@ex.com",
                "name": "",
                "roles": [],
                "permissions": [],
            ]
        }

        let svc = RegistrationService(config: config, net: mock)
        let user = try await svc.createUser(
            email: "opt@ex.com",
            password: "P@ssw0rd",
            name: nil,
            roles: []
        )
        XCTAssertEqual(user.id, "u2")
        XCTAssertEqual(user.email, "opt@ex.com")
    }

    func test_inviteUser_returns_message() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(
            baseURL: URL(string: "http://unit.test")!
        )

        mock.responder = { _, path, method, _, body in
            XCTAssertEqual(path, Endpoints.inviteUser)  // "/api/users/invite"
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(body?["email"] as? String, "new@ex.com")
            XCTAssertEqual(body?["tenantId"] as? String, "TENANT")
            XCTAssertEqual(body?["name"] as? String, "New User")
            return ["message": "invited"]
        }

        let svc = RegistrationService(config: config, net: mock)
        let msg = try await svc.inviteUser(
            email: "new@ex.com",
            name: "New User",
            tenantId: "TENANT"
        )
        XCTAssertEqual(msg, "invited")
    }
}
