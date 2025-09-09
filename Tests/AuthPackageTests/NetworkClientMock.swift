//
//  NetworkClientMock.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

@testable import AuthPackage

final class NetworkClientMock: NetworkClient {
    struct Key: Hashable {
        let path: String
        let method: HTTPMethod
    }
    private var map: [Key: Any] = [:]

    func register<T: Decodable>(
        _ type: T.Type,
        path: String,
        method: HTTPMethod,
        value: T
    ) {
        map[Key(path: path, method: method)] = value
    }

    func send<T: Decodable>(
        baseURL: URL,
        path: String,
        method: HTTPMethod,
        headers: [String: String],
        body: [String: Any]?
    ) async throws -> T {
        guard let v = map[Key(path: path, method: method)] as? T else {
            throw APIError.server(
                status: 500,
                message: "No stub for \(method.rawValue) \(path)"
            )
        }
        return v
    }
}
