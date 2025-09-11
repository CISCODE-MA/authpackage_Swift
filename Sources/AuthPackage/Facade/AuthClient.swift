//
//  AuthClient.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import AuthenticationServices
import Foundation

public protocol AuthClientProtocol {
    // Core
    func login(email: String, password: String, tenantId: String?) async throws
        -> JWTClaims?
    func refreshIfNeeded() async throws -> String?
    func logout() async throws

    // Users
    func register(
        email: String,
        password: String,
        name: String?,
        tenantId: String,
        roles: [String]?
    ) async throws -> User
    func invite(email: String, name: String?, tenantId: String) async throws
        -> String?

    // Password reset
    func requestPasswordReset(email: String) async throws -> String?
    func resetPassword(token: String, newPassword: String) async throws
        -> String?

    // OAuth (Microsoft through backend)
    @MainActor
    func loginWithMicrosoft(from anchor: ASPresentationAnchor) async throws
        -> JWTClaims?

    // State
    var currentUser: User? { get }
    var tokens: Tokens? { get }
}

public final class AuthClient: AuthClientProtocol {

    // MARK: - Deps
    private let config: AuthConfiguration
    private let net: NetworkClient
    private let tokenStore: TokenStore

    // Services
    private let loginService: LoginServicing
    private let regService: RegistrationServicing
    private let resetService: PasswordResetServicing
    private let tokenService: TokenServicing

    // MARK: - State
    public private(set) var currentUser: User?
    public var tokens: Tokens? { try? tokenStore.load() }

    public init(
        config: AuthConfiguration,
        networkClient: NetworkClient = URLSessionNetworkClient(),
        tokenStore: TokenStore = InMemoryTokenStore()
    ) {
        self.config = config
        self.net = networkClient
        self.tokenStore = tokenStore

        self.loginService = LoginService(
            config: config,
            net: networkClient,
            tokens: tokenStore
        )
        self.regService = RegistrationService(
            config: config,
            net: networkClient
        )
        self.resetService = PasswordResetService(
            config: config,
            net: networkClient
        )
        self.tokenService = TokenService(
            config: config,
            net: networkClient,
            tokens: tokenStore
        )
    }

    // MARK: - Core
    public func login(email: String, password: String, tenantId: String?)
        async throws -> JWTClaims?
    {
        let result = try await loginService.login(
            email: email,
            password: password,
            tenantId: tenantId
        )
        guard let access = result.accessToken else {
            throw APIError.unauthorized
        }
        return JWTDecoder.decode(access)
    }

    public func refreshIfNeeded() async throws -> String? {
        try await tokenService.refresh(refreshToken: nil)
    }

    public func logout() async throws {
        try await tokenService.logout()
        currentUser = nil
    }

    // MARK: - Users
    public func register(
        email: String,
        password: String,
        name: String?,
        tenantId: String,
        roles: [String]? = nil
    ) async throws -> User {
        try await regService.createUser(
            email: email,
            password: password,
            name: name,
            tenantId: tenantId,
            roles: roles
        )
    }

    public func invite(email: String, name: String?, tenantId: String)
        async throws -> String?
    {
        try await regService.inviteUser(
            email: email,
            name: name,
            tenantId: tenantId
        )
    }

    // MARK: - Password reset
    public func requestPasswordReset(email: String) async throws -> String? {
        try await resetService.requestReset(email: email)
    }

    public func resetPassword(token: String, newPassword: String) async throws
        -> String?
    {
        try await resetService.reset(token: token, newPassword: newPassword)
    }

    // MARK: - OAuth (Microsoft via backend redirect → app scheme)
    @MainActor
    public func loginWithMicrosoft(from anchor: ASPresentationAnchor)
        async throws -> JWTClaims?
    {
        guard config.microsoftEnabled else { throw APIError.unknown }
        let oauth = OAuthWebAuthenticator(
            config: config,
            tokenStore: tokenStore
        )
        let t = try await oauth.signInMicrosoft(from: anchor)  // runs on main actor
        return JWTDecoder.decode(t.accessToken)
    }
}
