//
//  LoginServiceTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 16/09/2025.
//


import XCTest
@testable import AuthPackage

final class LoginServiceTests: XCTestCase {

    func test_login_sends_correct_request_and_saves_tokens() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()

        mock.responder = { _, path, method, headers, body in
            XCTAssertEqual(path, Endpoints.login) // "/api/auth/clients/login"
            XCTAssertEqual(method, .POST)
            XCTAssertEqual(headers["Content-Type"], "application/json")
            XCTAssertEqual(body?["email"] as? String, "dev@ex.com")
            XCTAssertEqual(body?["password"] as? String, "Pass123!")
            return ["message": "ok", "accessToken": "AT", "refreshToken": "RT"]
        }

        let sut = LoginService(config: config, net: mock, tokens: store)
        let res = try await sut.login(email: "dev@ex.com", password: "Pass123!")

        XCTAssertEqual(res.message, "ok")
        XCTAssertEqual(try store.load()?.accessToken, "AT")
        XCTAssertEqual(try store.load()?.refreshToken, "RT")
    }

    func test_login_does_not_save_when_accessToken_missing() async throws {
        let mock = MockNetworkClient()
        let config = AuthConfiguration(baseURL: URL(string: "http://unit.test")!)
        let store = InMemoryTokenStore()

        mock.responder = { _,_,_,_,_ in ["message":"invalid credentials"] }

        let sut = LoginService(config: config, net: mock, tokens: store)
        let res = try await sut.login(email: "x@ex.com", password: "nope")

        XCTAssertEqual(res.message, "invalid credentials")
        XCTAssertNil(try store.load())
    }
}
