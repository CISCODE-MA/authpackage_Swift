//
//  AuthClient.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol AuthClientProtocol: Sendable {
    // Registration
    func register(
        fname: String, lname: String, username: String, email: String,
        phone: String, password: String, roles: [String]
    ) async throws -> User?
    func verifyEmail(token: String) async throws

    // Login + OTP
    func loginStart(identifier: String, password: String, rememberMe: Bool)
        async throws -> (otpSentTo: String?, debugOTP: String?)
    func verifyOTP(identifier: String, otp: String) async throws -> User

    // Session
    func refreshIfNeeded() async throws
    func logout() async throws
    var currentUser: User? { get }
    var accessToken: String? { get }
}

public final class AuthClient: AuthClientProtocol {
    private let config: AuthConfiguration
    private let net: NetworkClient
    private let tokens: TokenStore

    private let loginService: LoginServicing
    private let otpService: OTPServicing
    private let regService: RegistrationServicing
    private let resetService: PasswordResetServicing
    private let tokenService: TokenServicing

    public private(set) var currentUser: User?
    public var accessToken: String? { (try? tokens.load())?.accessToken }

    public init(
        config: AuthConfiguration,
        networkClient: NetworkClient = URLSessionNetworkClient(),
        tokenStore: TokenStore = InMemoryTokenStore()
    ) {
        self.config = config
        self.net = networkClient
        self.tokens = tokenStore

        self.loginService = LoginService(config: config, net: networkClient)
        self.otpService = OTPService(
            config: config, net: networkClient, tokens: tokenStore)
        self.regService = RegistrationService(
            config: config, net: networkClient)
        self.resetService = PasswordResetService(
            config: config, net: networkClient)
        self.tokenService = TokenService(
            config: config, net: networkClient, tokens: tokenStore)
    }

    // MARK: Registration
    public func register(
        fname: String, lname: String, username: String, email: String,
        phone: String, password: String, roles: [String]
    ) async throws -> User? {
        let (_, user, _) = try await regService.register(
            fname: fname, lname: lname, username: username, email: email,
            phone: phone, password: password, roles: roles)
        return user
    }

    public func verifyEmail(token: String) async throws {
        _ = try await regService.verifyEmail(token: token)
    }

    // MARK: Login + OTP
    public func loginStart(
        identifier: String, password: String, rememberMe: Bool
    ) async throws -> (String?, String?) {
        let (_, user, otpCode, _) = try await loginService.login(
            identifier: identifier, password: password, rememberMe: rememberMe)
        // user may be present for convenience; not authenticated yet
        return (user?.email, otpCode)  // otpCode may be omitted in prod
    }

    public func verifyOTP(identifier: String, otp: String) async throws -> User
    {
        let (_, user, _) = try await otpService.verify(
            identifier: identifier, otp: otp)
        guard let user else { throw APIError.unknown }
        self.currentUser = user
        return user
    }

    // MARK: Session
    public func refreshIfNeeded() async throws {
        let current = try tokens.load()
        // If you track expiry, use it; here we always try to refresh if possible
        _ = try await tokenService.refresh(using: current?.refreshToken)
    }

    public func logout() async throws {
        if let access = try tokens.load()?.accessToken {
            _ = try await tokenService.logout(accessToken: access)
        }
        try? tokens.clear()
        currentUser = nil
    }
}
