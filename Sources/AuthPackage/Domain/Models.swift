//
//  Models.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

/// Canonical user shape aligned with backend (clients + users).
public struct User: Codable, Equatable, Sendable {
    public let id: String
    public let email: String
    public let name: String?
    public let tenantId: String?  // backend may omit; keep optional
    public let roles: [String]
    public let permissions: [String]

    public init(
        id: String,
        email: String,
        name: String?,
        tenantId: String?,
        roles: [String],
        permissions: [String]
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.tenantId = tenantId
        self.roles = roles
        self.permissions = permissions
    }
}

/// Tokens we store locally.
public struct Tokens: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiry: Date?

    public init(accessToken: String, refreshToken: String?, expiry: Date? = nil)
    {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiry = expiry
    }
}

// MARK: - UserProfile 
public struct UserProfile: Codable, Equatable, Sendable {
  public var id: UUID
  public var avatarURL: URL?
  public var username: String
  public var email: String
  public var phoneNumber: String?

  public init(
    id: UUID,
    avatarURL: URL? = nil,
    username: String,
    email: String,
    phoneNumber: String? = nil
  ) {
    self.id = id
    self.avatarURL = avatarURL
    self.username = username
    self.email = email
    self.phoneNumber = phoneNumber
  }
}

// Lightweight rules (UI can show nicer messages)
public enum ProfileRules {
  public static func validateUsername(_ v: String) -> String? {
    v.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
      ? nil : "Username must be at least 2 characters."
  }

  public static func validateEmail(_ v: String) -> String? {
    let rx = try! NSRegularExpression(
      pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#,
      options: [.caseInsensitive]
    )
    return rx.firstMatch(in: v, range: NSRange(location: 0, length: v.utf16.count)) == nil
      ? "Enter a valid email."
      : nil
  }
}
