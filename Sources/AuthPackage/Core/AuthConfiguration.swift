//
//  AuthConfiguration.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public struct AuthConfiguration: Sendable {
    public let baseURL: URL
    /// If your backend sets refresh token in HttpOnly cookie, you can set this true.
    public let refreshUsesCookie: Bool

    public init(baseURL: URL, refreshUsesCookie: Bool = true) {
        self.baseURL = baseURL
        self.refreshUsesCookie = refreshUsesCookie
    }
}
