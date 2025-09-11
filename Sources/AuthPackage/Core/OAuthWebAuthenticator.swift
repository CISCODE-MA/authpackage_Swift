//
//  OAuthWebAuthenticator.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

import AuthenticationServices
import Foundation

@MainActor
public final class OAuthWebAuthenticator: NSObject,
    ASWebAuthenticationPresentationContextProviding
{
    private let config: AuthConfiguration
    private let tokenStore: TokenStore
    private weak var anchor: ASPresentationAnchor?

    public init(config: AuthConfiguration, tokenStore: TokenStore) {
        self.config = config
        self.tokenStore = tokenStore
    }

    // MARK: - Microsoft via backend → deep link back to app
    public func signInMicrosoft(from anchor: ASPresentationAnchor) async throws
        -> Tokens
    {
        guard let scheme = config.redirectScheme, !scheme.isEmpty else {
            throw APIError.invalidURL
        }
        self.anchor = anchor

        // Build start URL:  http(s)://<base>/api/auth/microsoft?redirect=<scheme>://auth/callback
        var comps = URLComponents(
            url: config.baseURL,
            resolvingAgainstBaseURL: false
        )
        comps?.path = Endpoints.microsoft
        comps?.queryItems = [
            URLQueryItem(name: "redirect", value: "\(scheme)://auth/callback")
        ]
        guard let startURL = comps?.url else {
            throw APIError.invalidURL
        }

        print("[OAuth] startURL =", startURL.absoluteString)

        return try await withCheckedThrowingContinuation {
            [weak self] (cont: CheckedContinuation<Tokens, Error>) in
            guard let self = self else {
                return cont.resume(throwing: APIError.unknown)
            }

            let session = ASWebAuthenticationSession(
                url: startURL,
                callbackURLScheme: scheme
            ) { callbackURL, error in
                // Debug: see exactly what we got
                print(
                    "[OAuth] completion url =",
                    callbackURL?.absoluteString ?? "nil"
                )
                print("[OAuth] completion err =", String(describing: error))

                if let err = error as? ASWebAuthenticationSessionError,
                    err.code == .canceledLogin
                {
                    return cont.resume(throwing: APIError.unknown)
                }
                guard let url = callbackURL else {
                    return cont.resume(throwing: APIError.unknown)
                }

                // Expect: authdemo://auth/callback?accessToken=...&refreshToken=...
                guard
                    let qi = URLComponents(
                        url: url,
                        resolvingAgainstBaseURL: false
                    )?.queryItems
                else {
                    return cont.resume(throwing: APIError.unknown)
                }
                let access = qi.first(where: { $0.name == "accessToken" })?
                    .value
                let refresh = qi.first(where: { $0.name == "refreshToken" })?
                    .value

                guard let accessToken = access, !accessToken.isEmpty else {
                    return cont.resume(throwing: APIError.unauthorized)
                }
                let tokens = Tokens(
                    accessToken: accessToken,
                    refreshToken: refresh
                )
                do { try self.tokenStore.save(tokens) } catch
                { /* ignore save errors */  }
                cont.resume(returning: tokens)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
//            if #available(iOS 13.4, *) {
//                session.canStart()  // no-op, but keeps analyzer happy
//            }
            session.start()
        }
    }

    // Anchor for ASWebAuthenticationSession
    public func presentationAnchor(for session: ASWebAuthenticationSession)
        -> ASPresentationAnchor
    {
        anchor ?? ASPresentationAnchor()
    }
}
