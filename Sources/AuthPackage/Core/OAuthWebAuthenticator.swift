// OAuthWebAuthenticator.swift

import AuthenticationServices
import Foundation

@MainActor
public final class OAuthWebAuthenticator: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let config: AuthConfiguration
    private let tokenStore: TokenStore
    private weak var anchor: ASPresentationAnchor?

    // ✅ Hold a strong ref to the session while it's running
    private var currentSession: ASWebAuthenticationSession?

    public init(config: AuthConfiguration, tokenStore: TokenStore) {
        self.config = config
        self.tokenStore = tokenStore
    }

    public func signInMicrosoft(from anchor: ASPresentationAnchor) async throws -> Tokens {
        guard let scheme = config.redirectScheme, !scheme.isEmpty else { throw APIError.invalidURL }
        self.anchor = anchor

        var comps = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)
        comps?.path = Endpoints.microsoft // Ensure this matches backend mount (e.g. "/api/auth/microsoft")
        comps?.queryItems = [URLQueryItem(name: "redirect", value: "\(scheme)://auth/callback")]
        guard let startURL = comps?.url else { throw APIError.invalidURL }

        return try await withCheckedThrowingContinuation { [weak self] (cont: CheckedContinuation<Tokens, Error>) in
            guard let self else { return cont.resume(throwing: APIError.unknown) }

            let session = ASWebAuthenticationSession(
                url: startURL,
                callbackURLScheme: scheme
            ) { [weak self] url, err in
                defer { self?.currentSession = nil }

                if let err = err as? ASWebAuthenticationSessionError {
                    if err.code == .canceledLogin {
                        return cont.resume(throwing: APIError.unknown)
                    }
                    return cont.resume(throwing: APIError.unknown)
                }

                guard let url,
                      let qi = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                      let access = qi.first(where: { $0.name == "accessToken" })?.value,
                      !access.isEmpty
                else {
                    return cont.resume(throwing: APIError.unauthorized)
                }

                let refresh = qi.first(where: { $0.name == "refreshToken" })?.value
                let tokens = Tokens(accessToken: access, refreshToken: refresh)
                do { try self?.tokenStore.save(tokens) } catch { }
                cont.resume(returning: tokens)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            self.currentSession = session
            _ = session.start()
        }
    }

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor ?? ASPresentationAnchor()
    }
}
