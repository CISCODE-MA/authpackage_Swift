//
//  AuthUIConfig.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import AuthPackage
import SwiftUI

public struct AuthUIConfig {
    public var baseURL: URL
    public var appScheme: String
    public var microsoftEnabled: Bool
    public var style: AuthUIStyleSheet

    public init(
        baseURL: URL,
        appScheme: String,
        microsoftEnabled: Bool = false,
        style: AuthUIStyleSheet = .default
    ) {
        self.baseURL = baseURL
        self.appScheme = appScheme
        self.microsoftEnabled = microsoftEnabled
        self.style = style
    }

    public init(
        baseURL: URL,
        appScheme: String,
        microsoftEnabled: Bool = false,
        cssVariables: String
    ) {
        self.init(
            baseURL: baseURL,
            appScheme: appScheme,
            microsoftEnabled: microsoftEnabled,
            style: AuthUIStyleSheet.fromCSSVariables(cssVariables)
        )
    }
}
