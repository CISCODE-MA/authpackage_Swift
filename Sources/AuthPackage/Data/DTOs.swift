//
//  DTOs.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

import Foundation

// MARK: - Requests

struct LoginRequest: Encodable {
    let email: String
    let password: String
    let tenantId: String?
}

struct RegisterUserRequest: Encodable {
    let email: String
    let password: String
    let name: String?
    let tenanntId: String?
    let roles: [String]?
}

struct InviteserRequest: Encodable {
    let email: String
    let name: String
    let tenantId: String?
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let newPassword: String
}

struct RefreshBody: Encodable {
    let refreshToken: String?
}

// MARK: - Responses
struct UserDTO: Decodable {
    let id: String?
    let _id: String?
    let email: String
    let name: String?
    let tenantId: String?
    let roles: [String]?
    let permissions: [String]?
}

struct AuthEnvelope: Decodable {
    let message: String?
    let user: UserDTO?
    let accessToken: String?
    let refreshToken: String?
}

struct AccessTokenEnvelope: Decodable {
    let message: String?
    let accessToken: String?
}
