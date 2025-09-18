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
    /// Custom URL scheme (or universal link domain) your host app handles, e.g. "authdemo"
    public let redirectScheme: String?
    /// Feature flags
    public let microsoftEnabled: Bool
    public let googleEnabled: Bool
    public let facebookEnabled: Bool
    public let ephemeralWebSession: Bool

    public init(
        baseURL: URL,
        refreshUsesCookie: Bool = true,
        redirectScheme: String? = nil,
        microsoftEnabled: Bool = false,
        googleEnabled: Bool = false,
        facebookEnabled: Bool = false,
        ephemeralWebSession: Bool = true
    ) {
        self.baseURL = baseURL
        self.refreshUsesCookie = refreshUsesCookie
        self.redirectScheme = redirectScheme
        self.microsoftEnabled = microsoftEnabled
        self.googleEnabled = googleEnabled
        self.facebookEnabled = facebookEnabled
        self.ephemeralWebSession = ephemeralWebSession
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
    public let microsoftEnabled: Bool

    public init(
        enabled: Bool = true,
        tenant: String,
        clientID: String,
        redirectScheme: String,
        redirectURI: String,
        scopes: [String] = ["openid", "email", "profile", "offline_access"],
        useBuiltInWebOAuth: Bool = true,
        microsoftEnabled: Bool = true

    ) {
        self.enabled = enabled
        self.tenant = tenant
        self.clientID = clientID
        self.redirectScheme = redirectScheme
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.useBuiltInWebOAuth = useBuiltInWebOAuth
        self.microsoftEnabled = microsoftEnabled
    }
}
