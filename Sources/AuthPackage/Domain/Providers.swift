//
//  Providers.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

public enum SocialProvider: String, Sendable { case microsoft }

/// Credential produced by build-in-web OAuth or by host app (MSAL)
public struct SocialCredential: Sendable {
    public let provider: SocialProvider
    public let idToken: String?
    public let accessToken: String?
    public init(
        provider: SocialProvider,
        idToken: String? = nil,
        accessToken: String? = nil
    ) {
        self.provider = provider
        self.idToken = idToken
        self.accessToken = accessToken
    }
}
