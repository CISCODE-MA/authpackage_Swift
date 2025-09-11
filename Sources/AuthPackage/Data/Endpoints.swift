//
//  Endpoints.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//
import Foundation

enum Endpoints {
    // Auth
    static let login = "/api/auth/clients/login"
    static let logout = "/api/auth/logout"
    static let refresh = "/api/auth/refresh-token"

    // Registration (clients)
    static let registerClient = "/api/auth/clients/register"

    // Users (keep if you still use them elsewhere)
    static let registerUser = "/api/users"
    static let inviteUser = "/api/users/invite"

    // Password reset
    static let requestPasswordReset = "/api/auth/forgot-password"
    static let resetPassword = "/api/auth/reset-password"

    // Microsoft OAuth
    static let microsoft = "/api/auth/microsoft"
}
