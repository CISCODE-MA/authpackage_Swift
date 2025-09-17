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

    // Users (optional legacy)
    static let registerUser = "/api/users"
    static let inviteUser = "/api/users/invite"

    // Password reset
    static let requestPasswordReset = "/api/auth/forgot-password"
    static let resetPassword = "/api/auth/reset-password"

    // Microsoft OAuth
    static let microsoft = "/api/auth/microsoft"

    // Google OAuth
    static let google = "/api/auth/google"
    static let googleClient = "/api/auth/client/google"

    // Facebook OAuth
    static let facebook = "/api/auth/facebook"
    static let facebookClient = "/api/auth/client/facebook"
}
