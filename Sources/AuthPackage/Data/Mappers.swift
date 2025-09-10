//
//  Mappers.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

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
}
