//
//  NetworkClientMock.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

@testable import AuthPackage

final class NetworkClientMock: NetworkClient {
    var stub: Any!
    func send<T>(
        baseURL: URL, path: String, method: HTTPMethod,
        headers: [String: String], body: [String: Any]?
    ) async throws -> T where T: Decodable {
        return stub as! T
    }
}
