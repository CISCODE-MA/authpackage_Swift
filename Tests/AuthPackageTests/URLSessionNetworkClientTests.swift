import XCTest

@testable import AuthPackage

/// Tests for the URLSession-backed NetworkClient using URLProtocolStub.
final class URLSessionNetworkClientTests: XCTestCase {

    struct Echo: Codable, Equatable {
        let ok: Bool
        let message: String
    }

    private func makeClient() -> URLSessionNetworkClient {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: cfg)
        return URLSessionNetworkClient(session: session, decoder: JSONDecoder())
    }

    func test_success_decoding() async throws {
        let client = makeClient()
        let base = URL(string: "http://unit.test")!
        let path = "/echo"
        let url = URL(string: base.absoluteString + path)!
        let payload = try JSONEncoder().encode(Echo(ok: true, message: "hi"))

        URLProtocolStub.set([
            url: .init(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                body: payload
            )
        ])

        let result: Echo = try await client.send(
            baseURL: base,
            path: path,
            method: .GET,
            headers: [:],
            body: nil
        )
        XCTAssertEqual(result, Echo(ok: true, message: "hi"))
        URLProtocolStub.removeAll()
    }

    func test_post_json_body_and_headers() async throws {
        let client = makeClient()
        let base = URL(string: "http://unit.test")!
        let path = "/echo"
        let url = URL(string: base.absoluteString + path)!
        let payload = try JSONEncoder().encode(
            Echo(ok: true, message: "posted")
        )

        URLProtocolStub.set([
            url: .init(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                body: payload
            )
        ])

        let _: Echo = try await client.send(
            baseURL: base,
            path: path,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: ["x": "y"]
        )
        // If decoding succeeds, it means request reached the stub URL exactly.
        URLProtocolStub.removeAll()
    }

    func test_server_error_maps_to_APIError_network_with_serverText() async {
        let client = makeClient()
        let base = URL(string: "http://unit.test")!
        let path = "/echo"
        let url = URL(string: base.absoluteString + path)!
        let body = Data(#"{"message":"Nope"}"#.utf8)

        URLProtocolStub.set([
            url: .init(
                statusCode: 400,
                headers: ["Content-Type": "application/json"],
                body: body
            )
        ])

        do {
            let _: Echo = try await client.send(
                baseURL: base,
                path: path,
                method: .GET,
                headers: [:],
                body: nil
            )
            XCTFail("Expected error")
        } catch APIError.network(let detail) {
            XCTAssertTrue(detail.contains("server(status: 400"))
            XCTAssertTrue(detail.contains("Nope"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        URLProtocolStub.removeAll()
    }

    func test_decoding_failure_maps_to_APIError_network_with_decodingText()
        async
    {
        let client = makeClient()
        let base = URL(string: "http://unit.test")!
        let path = "/echo"
        let url = URL(string: base.absoluteString + path)!
        let bad = Data(#"{"wrong":true}"#.utf8)

        URLProtocolStub.set([
            url: .init(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                body: bad
            )
        ])

        do {
            let _: Echo = try await client.send(
                baseURL: base,
                path: path,
                method: .GET,
                headers: [:],
                body: nil
            )
            XCTFail("Expected decoding error")
        } catch APIError.network(let detail) {
            XCTAssertTrue(
                detail.contains("decoding(") || detail.contains("keyNotFound")
                    || detail.contains("typeMismatch")
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        URLProtocolStub.removeAll()
    }
}
