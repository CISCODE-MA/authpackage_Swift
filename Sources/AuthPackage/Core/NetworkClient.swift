//
//  NetworkClient.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol NetworkClient {
    func send<T: Decodable>(
        baseURL: URL,
        path: String,
        method: HTTPMethod,
        headers: [String: String],
        bode: [String: Any]?
    ) async throws -> T
}
