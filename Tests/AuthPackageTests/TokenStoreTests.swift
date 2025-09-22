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

    func test_new_code_hits_init_save_load_clear() throws {
        // init → covers the empty initializer
        let store = InMemoryTokenStore()

        // save → covers the assignment body
        let t = Tokens(accessToken: "AA", refreshToken: "RR", expiry: nil)
        try store.save(t)

        // load → covers the return expression
        XCTAssertEqual(try store.load(), t)

        // clear → covers the nil-assignment
        try store.clear()
        XCTAssertNil(try store.load())
    }

}

final class FakeKeychain: KeychainClient {
    var storage: Data?
    func add(_ query: CFDictionary) -> OSStatus {
        // On duplicate, SecItemAdd returns errSecDuplicateItem; simulate by presence.
        if storage != nil { return errSecDuplicateItem }
        let dict = query as! [String: Any]
        storage = dict[kSecValueData as String] as? Data
        return errSecSuccess
    }
    func update(_ query: CFDictionary, _ attributesToUpdate: CFDictionary)
        -> OSStatus
    {
        let dict = attributesToUpdate as! [String: Any]
        storage = dict[kSecValueData as String] as? Data
        return errSecSuccess
    }
    func copyMatching(
        _ query: CFDictionary,
        _ result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        guard let data = storage else { return errSecItemNotFound }
        result?.pointee = data as CFData
        return errSecSuccess
    }
    func delete(_ query: CFDictionary) -> OSStatus {
        storage = nil
        return errSecSuccess
    }
}

func test_keychain_roundtrip_and_clear() throws {
    let kc = FakeKeychain()
    let sut = KeychainTokenStore(service: "svc", account: "acc", keychain: kc)

    let t1 = Tokens(
        accessToken: "A",
        refreshToken: "R",
        expiry: Date(timeIntervalSince1970: 1_700_000_000)
    )
    try sut.save(t1)
    XCTAssertEqual(try sut.load(), t1)

    // Overwrite and verify update path
    let t2 = Tokens(accessToken: "NEW", refreshToken: "R2", expiry: nil)
    try sut.save(t2)
    XCTAssertEqual(try sut.load(), t2)

    // Clear removes the item
    try sut.clear()
    XCTAssertNil(try sut.load())
}

func test_keychain_load_missing_returns_nil() throws {
    let sut = KeychainTokenStore(
        service: "svc",
        account: "acc",
        keychain: FakeKeychain()
    )
    XCTAssertNil(try sut.load())
}

func test_keychain_save_handles_duplicate_via_update() throws {
    let kc = FakeKeychain()
    let sut = KeychainTokenStore(service: "svc", account: "acc", keychain: kc)
    try sut.save(.init(accessToken: "AA", refreshToken: nil, expiry: nil))
    try sut.save(.init(accessToken: "BB", refreshToken: "RR", expiry: nil))  // triggers update path
    let loaded = try sut.load()
    XCTAssertEqual(loaded?.accessToken, "BB")
    XCTAssertEqual(loaded?.refreshToken, "RR")
}
