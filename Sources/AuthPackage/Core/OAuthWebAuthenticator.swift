//
//  OAuthWebAuthenticator.swift
//  AuthPackage
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

    // Hold a strong ref to the session while it's running
    private var currentSession: ASWebAuthenticationSession?

    public init(config: AuthConfiguration, tokenStore: TokenStore) {
        self.config = config
        self.tokenStore = tokenStore
    }

    // MARK: - Public entry points

    public func signInMicrosoft(from anchor: ASPresentationAnchor) async throws
        -> Tokens
    {
        try await signIn(providerPath: Endpoints.microsoft, from: anchor)
    }

    public func signInGoogle(from anchor: ASPresentationAnchor) async throws
        -> Tokens
    {
        try await signIn(providerPath: Endpoints.google, from: anchor)
    }

    public func signInFacebook(from anchor: ASPresentationAnchor) async throws
        -> Tokens
    {
        try await signIn(providerPath: Endpoints.facebook, from: anchor)
    }

    // MARK: - Shared implementation

    private func signIn(providerPath: String, from anchor: ASPresentationAnchor)
        async throws -> Tokens
    {
        guard let scheme = config.redirectScheme, !scheme.isEmpty else {
            throw APIError.invalidURL
        }
        self.anchor = anchor

        var comps = URLComponents(
            url: config.baseURL,
            resolvingAgainstBaseURL: false
        )
        comps?.path = providerPath
        comps?.queryItems = [
            URLQueryItem(name: "redirect", value: "\(scheme)://auth/callback"),
            URLQueryItem(name: "prompt", value: "select_account"),
        ]
        guard let startURL = comps?.url else { throw APIError.invalidURL }

        return try await withCheckedThrowingContinuation {
            [weak self] (cont: CheckedContinuation<Tokens, Error>) in
            guard let self else {
                return cont.resume(throwing: APIError.unknown)
            }

            let session = ASWebAuthenticationSession(
                url: startURL,
                callbackURLScheme: scheme
            ) { [weak self] url, err in
                defer { self?.currentSession = nil }

                if let err = err as? ASWebAuthenticationSessionError {
                    if err.code == .canceledLogin {
                        return cont.resume(throwing: APIError.unauthorized)
                    }
                    return cont.resume(throwing: APIError.unknown)
                }

                guard
                    let url,
                    let qi = URLComponents(
                        url: url,
                        resolvingAgainstBaseURL: false
                    )?.queryItems,
                    let access = qi.first(where: { $0.name == "accessToken" })?
                        .value,
                    !access.isEmpty
                else {
                    return cont.resume(throwing: APIError.unauthorized)
                }

                let refresh = qi.first(where: { $0.name == "refreshToken" })?
                    .value
                let tokens = Tokens(accessToken: access, refreshToken: refresh)
                do { try self?.tokenStore.save(tokens) } catch {}
                cont.resume(returning: tokens)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession =
                config.ephemeralWebSession

            self.currentSession = session
            _ = session.start()
        }
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding
    public func presentationAnchor(for session: ASWebAuthenticationSession)
        -> ASPresentationAnchor
    {
        anchor ?? ASPresentationAnchor()
    }
}
