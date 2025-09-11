import Foundation
import XCTest

@testable import AuthPackage

/// URLProtocol stub with thread-safe storage (no actor/async required).
/// Use URLProtocolStub.set(...) and .removeAll() in tests.
final class URLProtocolStub: URLProtocol {

    struct Stub {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }

    // MARK: - Thread-safe storage (boxed with a lock)
    private final class StubBox: @unchecked Sendable {
        static let shared = StubBox()
        private var stubs: [URL: Stub] = [:]
        private let lock = NSLock()

        func set(_ dict: [URL: Stub]) {
            lock.lock()
            stubs = dict
            lock.unlock()
        }
        func set(url: URL, stub: Stub) {
            lock.lock()
            stubs[url] = stub
            lock.unlock()
        }
        func removeAll() {
            lock.lock()
            stubs.removeAll()
            lock.unlock()
        }
        func get(_ url: URL) -> Stub? {
            lock.lock()
            defer { lock.unlock() }
            return stubs[url]
        }
    }

    // Convenience API for tests
    static func set(_ dict: [URL: Stub]) { StubBox.shared.set(dict) }
    static func set(url: URL, stub: Stub) {
        StubBox.shared.set(url: url, stub: stub)
    }
    static func removeAll() { StubBox.shared.removeAll() }
    static func stub(for url: URL) -> Stub? { StubBox.shared.get(url) }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest
    { request }

    override func startLoading() {
        guard let url = request.url, let stub = URLProtocolStub.stub(for: url)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: stub.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: stub.headers
        )!

        client?.urlProtocol(
            self,
            didReceive: response,
            cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
