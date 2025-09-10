//
//  MockAuthClient.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

public struct MockAuthClient: AuthClienting {
    public init() {}

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    public func register(
        firstName: String,
        lastName: String,
        username: String,
        email: String,
        phone: String,
        password: String
    ) async throws {
        if !isPreview { try await Task.sleep(nanoseconds: 150_000_000) }
        if email.lowercased().contains("fail") {
            throw AuthUIError.operationFailed("Email already used.")
        }
    }

    public func requestPasswordReset(email: String) async throws {
        if !isPreview { try await Task.sleep(nanoseconds: 120_000_000) }
        if !email.contains("@") {
            throw AuthUIError.invalidInput("Invalid email.")
        }
    }

    public func resetPassword(token: String, newPassword: String) async throws {
        if !isPreview { try await Task.sleep(nanoseconds: 120_000_000) }
        if token.isEmpty { throw AuthUIError.invalidInput("Missing token.") }
    }

    public func verifyEmail(token: String) async throws {
        if !isPreview { try await Task.sleep(nanoseconds: 100_000_000) }
        if token == "bad" { throw AuthUIError.operationFailed("Bad token.") }
    }
}
