//
//  APIError.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public enum APIError: Error, Equatable {
    case invalidURL
    case unauthorized
    case server(status: Int, message: String?)
    case decoding(String)
    case network(String)
    case unknown
}
