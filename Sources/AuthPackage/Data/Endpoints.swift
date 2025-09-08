//
//  Endpoints.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

enum Endpoints {
    static let login = "/api/auth/login"
    static let verifyOTP = "/api/auth/verify-otp"
    static let logout = "/api/auth/logout"
    static let register = "/api/auth/register"
    static let verifyEmail = "/api/verify/verify-email"
    static let requestPasswordReset = "/api/auth/request-password-reset"
    static let resetPassword = "/api/auth/reset-password"
    static let checkToken = "/api/verify/check-token"
    static let refresh = "/api/auth/refresh"
}
