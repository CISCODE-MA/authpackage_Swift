//
//  OAuthWebAuthenticator.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

import AuthenticationServices
import Foundation

/// Launches the backend's Microsoft OAuth (`/api/auth/microsoft?redirect=<scheme>://auth/callback`)
/// and captures tokens when the app is redirected back to the custom scheme.
@MainActor
public final class OAuthWebAuthenticator: NSObject,
    ASWebAuthenticationPresentationContextProviding
{

    private let config: AuthConfiguration
    private let tokenStore: TokenStore
    private weak var anchorWindow: ASPresentationAnchor?

    public init(config: AuthConfiguration, tokenStore: TokenStore) {
        self.config = config
        self.tokenStore = tokenStore
        super.init()
    }

    // ASWebAuthenticationPresentationContextProviding
    public func presentationAnchor(for session: ASWebAuthenticationSession)
        -> ASPresentationAnchor
    {
        anchorWindow ?? ASPresentationAnchor()
    }

    /// Starts the OAuth flow and returns the resulting tokens.
    public func signInMicrosoft(from anchor: ASPresentationAnchor) async throws
        -> Tokens
    {
        self.anchorWindow = anchor
        guard let scheme = config.redirectScheme else {
            throw APIError.invalidURL
        }

        // Compose start URL: GET /api/auth/microsoft?redirect=<scheme>://auth/callback
        var comps = URLComponents(
            url: config.baseURL,
            resolvingAgainstBaseURL: false
        )!
        comps.path = Endpoints.microsoft
        comps.queryItems = [
            URLQueryItem(name: "redirect", value: "\(scheme)://auth/callback")
        ]
        guard let startURL = comps.url else { throw APIError.invalidURL }

        return try await withCheckedThrowingContinuation { [weak self] cont in
            let session = ASWebAuthenticationSession(
                url: startURL,
                callbackURLScheme: scheme
            ) { url, err in
                guard err == nil, let url = url,
                    let items = URLComponents(
                        url: url,
                        resolvingAgainstBaseURL: false
                    )?.queryItems
                else {
                    return cont.resume(throwing: APIError.unknown)
                }

                let dict = Dictionary(
                    uniqueKeysWithValues: items.map {
                        ($0.name, $0.value ?? "")
                    }
                )
                let access = dict["accessToken"] ?? ""
                let refresh = dict["refreshToken"]

                guard !access.isEmpty else {
                    return cont.resume(throwing: APIError.unauthorized)
                }

                let tokens = Tokens(accessToken: access, refreshToken: refresh)
                do {
                    try self?.tokenStore.save(tokens)
                    cont.resume(returning: tokens)
                } catch {
                    cont.resume(throwing: error)
                }
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            _ = session.start()
        }
    }
}
