//
//  ProfileStore.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 06/10/2025.
//

import Foundation

public protocol ProfileStore {
    func load() async throws -> UserProfile
    func save(_ profile: UserProfile) async throws -> UserProfile
}

/// In-memory implementation so the feature works immediately.
/// Swap this with a real remote-backed store later without touching UI.
public final class InMemoryProfileStore: ProfileStore {
    private var profile: UserProfile

    public init(seed: UserProfile) { self.profile = seed }

    public func load() async throws -> UserProfile { profile }

    public func save(_ p: UserProfile) async throws -> UserProfile {
        profile = p
        return p
    }
}
