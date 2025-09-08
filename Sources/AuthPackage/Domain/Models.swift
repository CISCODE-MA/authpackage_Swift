//
//  Models.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public struct Fullname: Codable, Equatable, Sendable {
    public let fname: String
    public let lname: String
}

public struct User: Codable, Equatable, Sendable {
    public let id: String?
    public let fullname: Fullname?
    public let username: String
    public let email: String
    public let phoneNumber: String?
    public let roles: [String]
}
