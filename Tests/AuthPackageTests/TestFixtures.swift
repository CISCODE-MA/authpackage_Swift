//
//  TestFixtures.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

@testable import AuthPackage

// Minimal server envelope matching your DTOs
struct Envelope: Encodable {
    var message: String? = nil
    var token: String? = nil
    var accessToken: String? = nil
    var otpCode: String? = nil
    var rememberMe: Bool? = nil
    var user: UserDTO? = nil
}

// Correct argument order for your UserDTO.init(id:fullname:username:email:phoneNumber:roles:)
extension UserDTO {
    static func fixture(
        id: String = "u_1",
        email: String = "john@example.com",
        username: String = "johndoe",
        fname: String = "John",
        lname: String = "Doe",
        phoneNumber: String? = "+123456789"
    ) -> UserDTO {
        .init(
            id: id,
            fullname: FullnameDTO(fname: fname, lname: lname),
            username: username,
            email: email,
            phoneNumber: phoneNumber,
            roles: ["user"]
        )
    }
}
