//
//  AuthClienting.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

/// Minimal surface the UI layer depends on. Your core AuthPackage client can conform.
public protocol AuthClienting: Sendable {
    func register(
        firstName: String,
        lastName: String,
        username: String,
        email: String,
        phone: String,
        password: String
    ) async throws

    func requestPasswordReset(email: String) async throws
    func resetPassword(token: String, newPassword: String) async throws
    func verifyEmail(token: String) async throws
}

public enum AuthUIError: LocalizedError, Equatable {
    case invalidInput(String)
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let msg): return msg
        case .operationFailed(let msg): return msg
        }
    }
}
