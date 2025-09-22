//
//  OAuthWebAuthenticator.swift
//  AuthPackage
//

import AuthenticationServices
import Foundation

// MARK: - Lightweight seam to fake ASWebAuthenticationSession in tests

public protocol WebAuthSession: AnyObject {
    var prefersEphemeralWebBrowserSession: Bool { get set }
    func start() -> Bool
    func cancel()
}

public protocol WebAuthSessionFactory {
    func make(
        url: URL,
        callbackURLScheme: String,
        provider: ASWebAuthenticationPresentationContextProviding,
        completion: @escaping (URL?, Error?) -> Void
    ) -> WebAuthSession
}

final class RealWebAuthSession: WebAuthSession {
    private let inner: ASWebAuthenticationSession
    init(inner: ASWebAuthenticationSession) { self.inner = inner }
    var prefersEphemeralWebBrowserSession: Bool {
        get { inner.prefersEphemeralWebBrowserSession }
        set { inner.prefersEphemeralWebBrowserSession = newValue }
    }
    func start() -> Bool { inner.start() }
    func cancel() { inner.cancel() }
}

struct RealWebAuthSessionFactory: WebAuthSessionFactory {
    func make(
        url: URL,
        callbackURLScheme: String,
        provider: ASWebAuthenticationPresentationContextProviding,
        completion: @escaping (URL?, Error?) -> Void
    ) -> WebAuthSession {
        let s = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completion
        )
        s.presentationContextProvider = provider
        return RealWebAuthSession(inner: s)
    }
}

// MARK: - Authenticator

@MainActor
public final class OAuthWebAuthenticator: NSObject,
    ASWebAuthenticationPresentationContextProviding
{

    private let config: AuthConfiguration
    private let tokenStore: TokenStore
    private weak var anchor: ASPresentationAnchor?

    private let sessionFactory: WebAuthSessionFactory
    private var currentSession: WebAuthSession?

    // DESIGNATED initializer (no default argument)
    public init(
        config: AuthConfiguration,
        tokenStore: TokenStore,
        sessionFactory: WebAuthSessionFactory
    ) {
        self.config = config
        self.tokenStore = tokenStore
        self.sessionFactory = sessionFactory
    }

    // CONVENIENCE initializer to preserve old call sites
    public convenience init(
        config: AuthConfiguration,
        tokenStore: TokenStore
    ) {
        self.init(
            config: config,
            tokenStore: tokenStore,
            sessionFactory: RealWebAuthSessionFactory()
        )
    }

    // MARK: Public entry points

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

    // MARK: Shared implementation

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

            let session = sessionFactory.make(
                url: startURL,
                callbackURLScheme: scheme,
                provider: self,
                completion: { [weak self] url, err in
                    defer { self?.currentSession = nil }

                    if let err = err as? ASWebAuthenticationSessionError {
                        switch err.code {
                        case .canceledLogin:
                            cont.resume(throwing: APIError.unauthorized)
                        default: cont.resume(throwing: APIError.unknown)
                        }
                        return
                    }

                    guard
                        let url,
                        let qi = URLComponents(
                            url: url,
                            resolvingAgainstBaseURL: false
                        )?.queryItems,
                        let access = qi.first(where: {
                            $0.name == "accessToken"
                        })?.value,
                        !access.isEmpty
                    else {
                        return cont.resume(throwing: APIError.unauthorized)
                    }

                    let refresh = qi.first(where: { $0.name == "refreshToken" }
                    )?.value
                    let tokens = Tokens(
                        accessToken: access,
                        refreshToken: refresh
                    )

                    // Best-effort persistence; don’t fail the flow on store errors
                    do { try self?.tokenStore.save(tokens) } catch {}

                    cont.resume(returning: tokens)
                }
            )

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
