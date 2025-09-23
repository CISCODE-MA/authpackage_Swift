//
//  KeychainTokenStoreTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 23/09/2025.
//

import XCTest
import Security
@testable import AuthPackage

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


final class KeychainTokenStoreTests: XCTestCase {

    func test_roundtrip_save_load_update_and_clear() throws {
        let kc = FakeKeychain()
        let sut = KeychainTokenStore(service: "svc", account: "acc", keychain: kc)

        // Save v1
        let t1 = Tokens(accessToken: "A", refreshToken: "R", expiry: Date(timeIntervalSince1970: 1_700_000_000))
        try sut.save(t1)
        XCTAssertEqual(try sut.load(), t1)

        // Update (duplicate path)
        let t2 = Tokens(accessToken: "B", refreshToken: "R2", expiry: nil)
        try sut.save(t2)
        XCTAssertEqual(try sut.load(), t2)

        // Clear
        try sut.clear()
        XCTAssertNil(try sut.load())
    }

    func test_load_missing_returns_nil() throws {
        let sut = KeychainTokenStore(service: "svc", account: "acc", keychain: FakeKeychain())
        XCTAssertNil(try sut.load())
    }
}

final class ScriptableKeychain: KeychainClient {
    var addStatus: OSStatus = errSecSuccess
    var updateStatus: OSStatus = errSecSuccess
    var copyStatus: OSStatus = errSecSuccess
    var deleteStatus: OSStatus = errSecSuccess
    var stored: Data?

    func add(_ query: CFDictionary) -> OSStatus {
        if addStatus == errSecSuccess {
            let dict = query as! [String: Any]
            stored = dict[kSecValueData as String] as? Data
        }
        return addStatus
    }

    func update(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus {
        if updateStatus == errSecSuccess {
            let dict = attributesToUpdate as! [String: Any]
            stored = dict[kSecValueData as String] as? Data
        }
        return updateStatus
    }

    func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        if copyStatus == errSecSuccess, let s = stored {
            result?.pointee = s as CFData
        }
        return copyStatus
    }

    func delete(_ query: CFDictionary) -> OSStatus {
        if deleteStatus == errSecSuccess { stored = nil }
        return deleteStatus
    }
}

final class KeychainTokenStoreErrorTests: XCTestCase {

    func test_save_maps_notAvailable_to_network_error() {
        let kc = ScriptableKeychain()
        kc.addStatus = errSecNotAvailable  // SecItemAdd fails
        let sut = KeychainTokenStore(service: "svc", account: "acc", keychain: kc)

        do {
            try sut.save(.init(accessToken: "A", refreshToken: nil, expiry: nil))
            XCTFail("Expected error")
        } catch APIError.network {
            // ok: mapped to .network("Keychain not available")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func test_load_maps_authFailed_to_unauthorized() {
        let kc = ScriptableKeychain()
        kc.copyStatus = errSecAuthFailed  // SecItemCopyMatching fails
        let sut = KeychainTokenStore(service: "svc", account: "acc", keychain: kc)

        do {
            _ = try sut.load()
            XCTFail("Expected error")
        } catch APIError.unauthorized {
            // ok
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func test_load_maps_unknown_status_to_network_default() {
        let kc = ScriptableKeychain()
        kc.copyStatus = -34000  // some unknown OSStatus
        let sut = KeychainTokenStore(service: "svc", account: "acc", keychain: kc)

        do {
            _ = try sut.load()
            XCTFail("Expected error")
        } catch APIError.network {
            // ok: falls into default -> .network("Keychain status ...")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func test_clear_ignores_itemNotFound_but_propagates_other_errors() {
        // item not found => no throw
        do {
            let kc1 = ScriptableKeychain()
            kc1.deleteStatus = errSecItemNotFound
            let sut1 = KeychainTokenStore(service: "svc", account: "acc", keychain: kc1)
            try sut1.clear()
        } catch {
            XCTFail("Should not throw for errSecItemNotFound, got \(error)")
        }

        // not available => throw .network
        let kc2 = ScriptableKeychain()
        kc2.deleteStatus = errSecNotAvailable
        let sut2 = KeychainTokenStore(service: "svc", account: "acc", keychain: kc2)
        do {
            try sut2.clear()
            XCTFail("Expected error")
        } catch APIError.network {
            // ok
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }
}
