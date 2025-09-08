//
//  Endpoints.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

enum Endpoints {
    // Build paths relative to baseURL from AuthConfiguration
    static let login = "/auth/login"
    static let verifyOTP = "/auth/verify-otp"
    static let logout = "/auth/logout"
    static let register = "/auth/register"
    static let verifyEmail = "/auth/verify-email"
    static let requestPasswordRest = "/auth/request-password-reset"
    static let resetPassword = "/auth/reset-password"
//    static let checkToken = "/verify/check-token"
    static let refresh = "/auth/refresh"
}
