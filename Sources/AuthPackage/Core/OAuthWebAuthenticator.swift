//
//  OAuthWebAuthenticator.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

import AuthenticationServices
import Foundation

public protocol OAuthAuthenticating: AnyObject {
    func signInWithMicrosoft(from anchor: ASPresentationAnchor) async throws -> Tokens
}

public final class OAuthWebAuthenticator: NSObject, OAuthAuthenticating, ASWebAuthenticationPresentationContextProviding {
    private let config: AuthConfiguration
    private let tokens: TokenStore

    public init(config: AuthConfiguration, tokens: TokenStore) {
        self.config = config
        self.tokens = tokens
        super.init()
    }

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { ASPresentationAnchor() }

    public func signInWithMicrosoft(from anchor: ASPresentationAnchor) async throws -> Tokens {
        guard let scheme = config.redirectScheme else { throw APIError.invalidURL }

        // e.g. myapp://auth/callback
        let callback = "\(scheme)://auth/callback"

        // Ask backend to start Microsoft OAuth and redirect back to our app scheme
        var comps = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)!
        comps.path = Endpoints.microsoft
        comps.queryItems = [URLQueryItem(name: "redirect", value: callback)]
        guard let startURL = comps.url else { throw APIError.invalidURL }

        return try await withCheckedThrowingContinuation { [weak self] cont in
            let session = ASWebAuthenticationSession(
                url: startURL,
                callbackURLScheme: scheme
            ) { url, err in
                guard err == nil, let url = url else { return cont.resume(throwing: APIError.unknown) }
                do {
                    // Expect: myapp://auth/callback?accessToken=...&refreshToken=...
                    let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let q = comps?.queryItems ?? []
                    let access = q.first { $0.name == "accessToken" }?.value ?? ""
                    let refresh = q.first { $0.name == "refreshToken" }?.value
                    let t = Tokens(accessToken: access, refreshToken: refresh, expiry: nil)
                    try self?.tokens.save(t)
                    cont.resume(returning: t)
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
