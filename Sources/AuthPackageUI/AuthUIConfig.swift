//
//  AuthUIConfig.swift
//  AuthPackageUI
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import AuthPackage
import SwiftUI

public struct AuthUIConfig: Sendable {
    public var baseURL: URL
    public var appScheme: String
    public var microsoftEnabled: Bool
    public var style: AuthUIStyleSheet
    public var postLoginDeeplink: URL?   // NEW

    // Primary initializer (keeps existing 'style' usage)
    public init(
        baseURL: URL,
        appScheme: String,
        microsoftEnabled: Bool = false,
        style: AuthUIStyleSheet = .default,
        postLoginDeeplink: URL? = nil
    ) {
        self.baseURL = baseURL
        self.appScheme = appScheme
        self.microsoftEnabled = microsoftEnabled
        self.style = style
        self.postLoginDeeplink = postLoginDeeplink
    }

    // Convenience: build style from a CSS-like token string
    public init(
        baseURL: URL,
        appScheme: String,
        microsoftEnabled: Bool = false,
        cssVariables: String,
        postLoginDeeplink: URL? = nil
    ) {
        self.init(
            baseURL: baseURL,
            appScheme: appScheme,
            microsoftEnabled: microsoftEnabled,
            style: AuthUIStyleSheet.fromCSSVariables(cssVariables),
            postLoginDeeplink: postLoginDeeplink
        )
    }
}
