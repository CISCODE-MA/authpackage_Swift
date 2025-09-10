//
//  Endpoints.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//
import Foundation

enum Endpoints {
    // Auth
    static let login = "/api/auth/login"
    static let logout = "/api/auth/logout"
    static let refresh = "/api/auth/refresh-token"

    // Users
    static let registerUser = "/api/users"
    static let inviteUser = "/api/users/invite"
    
    // Password Reset
    static let requestPasswordReset = "/api/auth/forgot-password"
    static let resetPassword = "/api/auth/reset-password"
    
    // Microsot OAuth
    static let microsoft = "/api/auth/microsoft"

}
