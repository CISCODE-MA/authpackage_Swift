//
//  HostAppValidator.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

import Foundation

public enum HostAppValidation {
    /// Ensure the host app registered the custom URL scheme required for OAuth.
    public static func assertURLSchemePresent(expectedScheme: String) throws {
        /// Info.plist → CFBundleURLTypes → CFBundleURLSchemes
        guard
            let types = Bundle.main.object(
                forInfoDictionaryKey: "CFBundleURLTypes"
            ) as? [[String: Any]]
        else { throw APIError.invalidURL }

        let schemes: [String] =
            types
            .compactMap { $0["CFBundleURLSchemes"] as? [String] }
            .flatMap { $0 }
            .map { $0.lowercased() }

        guard schemes.contains(expectedScheme.lowercased()) else {
            throw APIError.invalidURL
        }
    }

}
