//
//  OAuthWebAuthenticator.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

import AuthenticationServices
import Foundation

@MainActor
public final class OAuthWebAuthenticator: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let config: AuthConfiguration
    private let tokenStore: TokenStore
    private weak var anchor: ASPresentationAnchor?

    public init(config: AuthConfiguration, tokenStore: TokenStore) {
        self.config = config
        self.tokenStore = tokenStore
    }

    public func signInMicrosoft(from anchor: ASPresentationAnchor) async throws -> Tokens {
        guard let scheme = config.redirectScheme, !scheme.isEmpty else { throw APIError.invalidURL }
        self.anchor = anchor

        var comps = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)
        comps?.path = Endpoints.microsoft
        comps?.queryItems = [URLQueryItem(name: "redirect", value: "\(scheme)://auth/callback")]
        guard let startURL = comps?.url else { throw APIError.invalidURL }

        return try await withCheckedThrowingContinuation { [weak self] (cont: CheckedContinuation<Tokens, Error>) in
            guard let self = self else { return cont.resume(throwing: APIError.unknown) }

            let session = ASWebAuthenticationSession(url: startURL, callbackURLScheme: scheme) { url, err in
                if let err = err as? ASWebAuthenticationSessionError, err.code == .canceledLogin {
                    return cont.resume(throwing: APIError.unknown)
                }
                guard let url = url,
                      let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                      let access = qi.first(where: { $0.name == "accessToken" })?.value,
                      !access.isEmpty else {
                    return cont.resume(throwing: APIError.unauthorized)
                }

                let refresh = qi.first(where: { $0.name == "refreshToken" })?.value
                let tokens = Tokens(accessToken: access, refreshToken: refresh)
                do { try self.tokenStore.save(tokens) } catch { /* ignore */ }
                cont.resume(returning: tokens)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor ?? ASPresentationAnchor()
    }
}
