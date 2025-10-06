//
//  InMemoryProfileStoreTests.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 06/10/2025.
//

import XCTest

@testable import AuthPackage

final class InMemoryProfileStoreTests: XCTestCase {

    func test_load_and_save_roundtrip() async throws {
        let seed = UserProfile(
            id: UUID(),
            avatarURL: URL(string: "https://x.y/z.png"),
            username: "Demo",
            email: "demo@example.com",
            phoneNumber: "1"
        )
        let store = InMemoryProfileStore(seed: seed)

        let loaded = try await store.load()
        XCTAssertEqual(loaded, seed)

        var next = loaded
        next.username = "New"
        next.phoneNumber = nil
        let saved = try await store.save(next)

        XCTAssertEqual(saved.username, "New")
        XCTAssertNil(saved.phoneNumber)

        let reloaded = try await store.load()
        XCTAssertEqual(reloaded, next)
    }

    func test_actor_serialization_last_write_wins() async throws {
        let seed = UserProfile(id: UUID(), username: "A", email: "a@b.com")
        let store = InMemoryProfileStore(seed: seed)

        async let s1: UserProfile = store.save(
            UserProfile(id: seed.id, username: "U1", email: "a@b.com")
        )
        async let s2: UserProfile = store.save(
            UserProfile(id: seed.id, username: "U2", email: "a@b.com")
        )
        async let s3: UserProfile = store.save(
            UserProfile(id: seed.id, username: "U3", email: "a@b.com")
        )
        _ = try await (s1, s2, s3)

        let final = try await store.load()
        XCTAssertTrue(["U1", "U2", "U3"].contains(final.username))
    }
}
