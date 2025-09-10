//
//  TestFixtures.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

@testable import AuthPackage

enum Fixtures {
    static let baseURL = URL(string: "https://api.example.test")!

    static let dtoUser = UserDTO(
        id: "u1",
        fullname: FullnameDTO(fname: "Jane", lname: "Doe"),
        username: "jane",
        email: "jane@example.com",
        phoneNumber: nil,
        roles: ["user"]
    )

    static let user = Mapper.user(dtoUser)

    static func envLoginNoOTP(token: String) -> AuthEnvelope {
        .init(
            message: "ok",
            user: dtoUser,
            otpCode: nil,
            rememberMe: true,
            accessToken: token,
            token: nil
        )
    }

    static func envLoginOTP(otp: String) -> AuthEnvelope {
        .init(
            message: "otp",
            user: dtoUser,
            otpCode: otp,
            rememberMe: nil,
            accessToken: nil,
            token: nil
        )
    }

    static func envVerifyOTP(token: String) -> AuthEnvelope {
        .init(
            message: "ok",
            user: dtoUser,
            otpCode: nil,
            rememberMe: nil,
            accessToken: token,
            token: nil
        )
    }

    static func envRefresh(token: String) -> AuthEnvelope {
        .init(
            message: "ok",
            user: nil,
            otpCode: nil,
            rememberMe: nil,
            accessToken: token,
            token: nil
        )
    }

    static let access1 = "access-1"
    static let access2 = "access-2"
}
