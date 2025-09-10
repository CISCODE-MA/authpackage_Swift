//
//  AuthConfiguration.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public struct AuthConfiguration: Sendable {
    public let baseURL: URL
    public let refreshUsesCookie: Bool
    public let providers: ProvidersConfig  // NEW

    public init(
        baseURL: URL,
        refreshUsesCookie: Bool = true,
        providers: ProvidersConfig = .disabled
    ) {
        self.baseURL = baseURL
        self.refreshUsesCookie = refreshUsesCookie
        self.providers = providers
    }
}

public struct ProvidersConfig: Sendable {
    public var microsoft: MicrosoftConfig?
    public static var disabled: ProvidersConfig { .init(microsoft: nil) }
    public init(microsoft: MicrosoftConfig? = nil) {
        self.microsoft = microsoft
    }
}

/// Microsoft Entra (Azure AD) config (tenant-aware)
public struct MicrosoftConfig: Sendable {
    /// Tenant: GUID or "organizations"/"common"
    public let enabled: Bool
    public let tenant: String
    public let clientID: String
    /// iOS redirect scheme & full redirect URI (host app must register scheme)
    public let redirectScheme: String
    public let redirectURI: String
    /// Typical: ["openid", "email", "profile", "offline_access"]
    public let scopes: [String]
    /// true = built-in web OAuth; false = BYOT (host app passes an MSAL token)
    public let useBuiltInWebOAuth: Bool

    public init(
        enabled: Bool = true,
        tenant: String,
        clientID: String,
        redirectScheme: String,
        redirectURI: String,
        scopes: [String] = ["openid", "email", "profile", "offline_access"],
        useBuiltInWebOAuth: Bool = true
    ) {
        self.enabled = enabled
        self.tenant = tenant
        self.clientID = clientID
        self.redirectScheme = redirectScheme
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.useBuiltInWebOAuth = useBuiltInWebOAuth
    }
}
