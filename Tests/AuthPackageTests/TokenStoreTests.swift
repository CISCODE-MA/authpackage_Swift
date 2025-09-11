import XCTest
@testable import AuthPackage

final class TokenStoreTests: XCTestCase {
    func test_inMemory_save_load_clear() throws {
        let store = InMemoryTokenStore()
        XCTAssertNil(try store.load())

        let tokens = Tokens(accessToken: "a", refreshToken: "r", expiry: Date())
        try store.save(tokens)

        let loaded = try store.load()
        XCTAssertEqual(loaded, tokens)

        try store.clear()
        XCTAssertNil(try store.load())
    }
}
