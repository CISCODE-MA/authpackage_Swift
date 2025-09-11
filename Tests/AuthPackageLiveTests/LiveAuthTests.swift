////
////  LiveAuthTests.swift (fixed setUpWithError)
////  AuthPackageLiveTests
////
//
//import XCTest
//@testable import AuthPackage
//
//final class LiveAuthTests: XCTestCase {
//    private var base: URL!
//    private var email: String!
//    private var password: String!
//
//    override func setUpWithError() throws {
//        guard let baseUrl = ProcessInfo.processInfo.environment["LIVE_BASE_URL"],
//              let url = URL(string: baseUrl) else {
//            throw XCTSkip("LIVE_BASE_URL not set — skipping live tests")
//        }
//        base = url
//        email = ProcessInfo.processInfo.environment["LIVE_EMAIL"] ?? "a@b.com"
//        password = ProcessInfo.processInfo.environment["LIVE_PASSWORD"] ?? "Secret123!"
//    }
//
//    func testLive_Login() async throws {
//        let client = AuthClient(config: AuthConfiguration(baseURL: base), tokenStore: InMemoryTokenStore())
//        let claims = try await client.login(email: email, password: password)
//        XCTAssertNotNil(claims, "Should receive JWT claims after login")
//        
//        let registeredClaims = try await client.register(email: email, password: password, name: name)
//        XCTAssertNotNil(registeredClaims, "Should receive user claims after registration")
//
//
//    }
//}
