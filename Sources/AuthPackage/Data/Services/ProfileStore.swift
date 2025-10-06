//
//  ProfileStore.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 06/10/2025.
//


import Foundation

public protocol ProfileStore {
  func load() async throws -> UserProfile
  func save(_ profile: UserProfile, avatarJPEG: Data?) async throws -> UserProfile
}

// In-memory default so you can run immediately.
public final class InMemoryProfileStore: ProfileStore {
  private var profile: UserProfile
  public init(seed: UserProfile) { self.profile = seed }

  public func load() async throws -> UserProfile { profile }

  public func save(_ p: UserProfile, avatarJPEG: Data?) async throws -> UserProfile {
    // Ignore avatar bytes in this stub; just keep the URL if present.
    profile = p
    return profile
  }
}
