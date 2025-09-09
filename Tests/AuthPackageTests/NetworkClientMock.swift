//
//  NetworkClientMock.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

@testable import AuthPackage

// File-scope eraser so we can encode any Encodable
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { self._encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

final class NetworkClientMock: NetworkClient {
    struct Key: Hashable {
        let method: HTTPMethod
        let path: String
    }
    enum Stub {
        case json(String)
        case encodable(Encodable)
        case error(Error)
    }

    private var stubs: [Key: Stub] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func stub(_ method: HTTPMethod, _ path: String, with stub: Stub) {
        stubs[Key(method: method, path: path)] = stub
    }

    func send<T: Decodable>(
        baseURL: URL,
        path: String,
        method: HTTPMethod,
        headers: [String: String],
        body: [String: Any]?
    ) async throws -> T {
        guard let stub = stubs[Key(method: method, path: path)] else {
            throw APIError.unknown
        }
        switch stub {
        case .error(let e):
            throw e
        case .json(let json):
            return try decoder.decode(T.self, from: Data(json.utf8))
        case .encodable(let value):
            let data = try encoder.encode(AnyEncodable(value))
            return try decoder.decode(T.self, from: data)
        }
    }
}
