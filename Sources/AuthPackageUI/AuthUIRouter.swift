//
//  AuthUIRouter.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//
#if os(iOS)

    @preconcurrency import AuthPackage
    import Foundation

    /// Shared container for config + client + deep-link handling.
    @MainActor
    public final class AuthUIRouter: ObservableObject {
        public static let shared = AuthUIRouter()

        @Published public private(set) var config: AuthUIConfig!
        public private(set) var client: AuthClientProtocol!

        /// Set when a reset-password deep link arrives.
        @Published public var pendingResetToken: String? = nil

        public func configure(config: AuthUIConfig, client: AuthClientProtocol)
        {
            self.config = config
            self.client = client
        }

        /// Supports `<scheme>://reset-password?token=...`.
        @discardableResult
        public func handle(url: URL) -> Bool {
            guard
                let comps = URLComponents(
                    url: url,
                    resolvingAgainstBaseURL: false
                ),
                comps.scheme == config.appScheme
            else { return false }

            if (url.host ?? "") == "reset-password",
                let token = comps.queryItems?.first(where: {
                    $0.name == "token"
                })?
                .value
            {
                pendingResetToken = token
                return true
            }
            return false
        }
    }
#endif
