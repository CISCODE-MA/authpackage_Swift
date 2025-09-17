//
//  AuthUIConfig.swift
//  AuthPackageUI
//
//  Created by Zaid MOUMNI on 12/09/2025.
//
#if os(iOS)
    import AuthPackage
    import SwiftUI

    public struct AuthUIConfig: Sendable {
        public var baseURL: URL
        public var appScheme: String
        public var microsoftEnabled: Bool
        public var googleEnabled: Bool  // NEW
        public var facebookEnabled: Bool  // NEW
        public var style: AuthUIStyleSheet
        public var postLoginDeeplink: URL?

        public init(
            baseURL: URL,
            appScheme: String,
            microsoftEnabled: Bool = false,
            googleEnabled: Bool = false,  // NEW
            facebookEnabled: Bool = false,  // NEW
            style: AuthUIStyleSheet = .default,
            postLoginDeeplink: URL? = nil
        ) {
            self.baseURL = baseURL
            self.appScheme = appScheme
            self.microsoftEnabled = microsoftEnabled
            self.googleEnabled = googleEnabled
            self.facebookEnabled = facebookEnabled
            self.style = style
            self.postLoginDeeplink = postLoginDeeplink
        }

        public init(
            baseURL: URL,
            appScheme: String,
            microsoftEnabled: Bool = false,
            googleEnabled: Bool = false,  // NEW
            facebookEnabled: Bool = false,  // NEW
            cssVariables: String,
            postLoginDeeplink: URL? = nil
        ) {
            self.init(
                baseURL: baseURL,
                appScheme: appScheme,
                microsoftEnabled: microsoftEnabled,
                googleEnabled: googleEnabled,
                facebookEnabled: facebookEnabled,
                style: AuthUIStyleSheet.fromCSSVariables(cssVariables),
                postLoginDeeplink: postLoginDeeplink
            )
        }
    }
#endif
