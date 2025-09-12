//
//  AuthUIEnvironment.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import SwiftUI

private struct AuthUIStyleKey: EnvironmentKey {
    static let defaultValue: AuthUIStyleSheet = .default
}

extension EnvironmentValues {
    public var authUIStyle: AuthUIStyleSheet {
        get {
            self[AuthUIStyleKey.self]
        }
        set {
            self[AuthUIStyleKey.self] = newValue
        }
    }
}
