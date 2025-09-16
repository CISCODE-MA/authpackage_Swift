import XCTest
@testable import AuthPackage

final class EndpointsTests: XCTestCase {
    func test_constants_match_expected_paths() {
        XCTAssertEqual(Endpoints.login, "/api/auth/clients/login")
        XCTAssertEqual(Endpoints.logout, "/api/auth/logout")
        XCTAssertEqual(Endpoints.refresh, "/api/auth/refresh-token")
        XCTAssertEqual(Endpoints.registerClient, "/api/auth/clients/register")
        XCTAssertEqual(Endpoints.registerUser, "/api/users")
        XCTAssertEqual(Endpoints.inviteUser, "/api/users/invite")
        XCTAssertEqual(Endpoints.requestPasswordReset, "/api/auth/forgot-password")
        XCTAssertEqual(Endpoints.resetPassword, "/api/auth/reset-password")
        XCTAssertEqual(Endpoints.microsoft, "/api/auth/microsoft")
    }
}
