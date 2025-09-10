//
//  String+AuthUtils.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

public extension String {
    var authTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var authIsValidEmail: Bool {
        // Fast local check; server is the source of truth.
        contains("@") && contains(".")
    }
}
