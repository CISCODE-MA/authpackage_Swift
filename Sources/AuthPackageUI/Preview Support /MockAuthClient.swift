//
//  MockAuthClient.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

public struct MockAuthClient: AuthClienting {
    public init() {}

    public func register(
        firstName: String,
        lastName: String,
        username: String,
        email: String,
        phone: String,
        password: String
    ) async throws {
        try await Task.sleep(nanoseconds: 350_000_000)
        if email.lowercased().contains("fail") {
            throw AuthUIError.operationFailed("Email already used.")
        }
    }

    public func requestPasswordReset(email: String) async throws {
        try await Task.sleep(nanoseconds: 250_000_000)
        if !email.contains("@") {
            throw AuthUIError.invalidInput("Invalid email.")
        }
    }

    public func resetPassword(token: String, newPassword: String) async throws {
        try await Task.sleep(nanoseconds: 250_000_000)
        if token.isEmpty { throw AuthUIError.invalidInput("Missing token.") }
    }

    public func verifyEmail(token: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        if token == "bad" { throw AuthUIError.operationFailed("Bad token.") }
    }
}
