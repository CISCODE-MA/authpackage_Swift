//
//  DTOs.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public struct AuthEnvelope: Codable, Sendable {
    public let message: String?
    public let user: UserDTO?
    public let otpCode: String?
    public let rememberMe: Bool?
    public let accessToken: String?
    public let token: String?
}

public struct UserDTO: Codable, Sendable {
    public let id: String?
    public let fullname: FullnameDTO?
    public let username: String
    public let email: String
    public let phoneNumber: String?
    public let roles: [String]
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullname, username, email, phoneNumber, roles
    }
}

public struct FullnameDTO: Codable, Sendable {
    public let fname: String
    public let lname: String
}
