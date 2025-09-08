//
//  Mappers.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

enum Mapper {
    static func user(_ dto: UserDTO) -> User {
        User(
            id: dto.id,
            fullname: dto.fullname.map { Fullname(fname: $0.fname, lname: $0.lname) },
            username: dto.username,
            email: dto.email,
            phoneNumber: dto.phoneNumber,
            roles: dto.roles
        )
    }
}
