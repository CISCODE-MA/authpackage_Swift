//
//  Mappers.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

// Sources/AuthPackage/Data/Mappers.swift

enum Mapper {
    static func user(_ dto: UserDTO) -> User {
        let id = dto.id ?? dto._id ?? UUID().uuidString
        return User(
            id: id,
            email: dto.email,
            name: dto.name,
            tenantId: dto.tenantId,
            roles: dto.roles ?? [],
            permissions: dto.permissions ?? []
        )
    }

    static func user(from client: ClientRegistrationResponse) -> User {
        return User(
            id: client.id ?? UUID().uuidString,
            email: client.email,
            name: client.name,
            tenantId: nil,
            roles: client.roles ?? [],
            permissions: []  // permissions aren’t returned on register
        )
    }
}
