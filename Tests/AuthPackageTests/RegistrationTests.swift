import XCTest
@testable import AuthPackage

final class RegistrationTests: XCTestCase {

    func testRegisterAndVerifyEmail() async throws {
        let base = URL(string: "http://localhost")!
        let net = NetworkClientMock()

        // Stub register
        let user = UserDTO.fixture()
        net.stub(.POST, Endpoints.register, with: .encodable(
            Envelope(message: "ok", token: "email_tkn_123", user: user)
        ))
        // Stub verify email
        net.stub(.GET, "\(Endpoints.verifyEmail)?token=email_tkn_123", with: .encodable(
            Envelope(message: "verified", user: user)
        ))

        let config = AuthConfiguration(baseURL: base)
        let store = InMemoryTokenStore()
        let client = AuthClient(config: config, networkClient: net, tokenStore: store)

        // register
        let u = try await client.register(
            fname: "John", lname: "Doe",
            username: "johndoe",
            email: "john@example.com",
            phone: "+123456789",
            password: "pw",
            roles: ["user"]
        )
        XCTAssertEqual(u?.email, "john@example.com")

        // verify
        try await client.verifyEmail(token: "email_tkn_123")
    }
}
