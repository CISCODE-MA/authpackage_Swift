import XCTest

@testable import AuthPackage

final class TokenStoreTests: XCTestCase {

    func test_inMemory_save_load_clear() throws {
        let store = InMemoryTokenStore()
        XCTAssertNil(try store.load())

        let tokens = Tokens(accessToken: "a", refreshToken: "r", expiry: Date())
        try store.save(tokens)
        XCTAssertEqual(try store.load(), tokens)

        try store.clear()
        XCTAssertNil(try store.load())
    }

    func test_overwrite_tokens() throws {
        let store = InMemoryTokenStore()
        try store.save(
            .init(accessToken: "OLD", refreshToken: "R1", expiry: nil)
        )
        try store.save(
            .init(accessToken: "NEW", refreshToken: "R2", expiry: nil)
        )
        let loaded = try store.load()
        XCTAssertEqual(loaded?.accessToken, "NEW")
        XCTAssertEqual(loaded?.refreshToken, "R2")
    }

    func test_save_load_roundtrips_tokens_struct() throws {
        let store = InMemoryTokenStore()
        let exp = Date(timeIntervalSince1970: 1_700_000_000)
        let tokens = Tokens(accessToken: "A", refreshToken: "R", expiry: exp)
        try store.save(tokens)
        XCTAssertEqual(try store.load(), tokens)  // covers expiry via Equatable
    }

}
