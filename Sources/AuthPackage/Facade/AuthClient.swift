//
//  AuthClient.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol AuthClientProtocol {
    // Registration
    func register(
        fname: String,
        lname: String,
        username: String,
        email: String,
        phone: String,
        password: String,
        roles: [String]
    ) async throws -> User?
    func verifyEmail(token: String) async throws

    // Login + OTP
    func loginStart(identifier: String, password: String, rememberMe: Bool)
        async throws -> (otpSentTo: String?, debugOTP: String?)
    func verifyOTP(identifier: String, otp: String) async throws -> User

    // Password Reset
    func requestPasswordReset(email: String) async throws
    func resetPassword(token: String, newPassword: String) async throws

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

    private let socialService: SocialLoginServicing
    private let oauthWeb: OAuthWebAuthenticator

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

        self.socialService = SocialLoginService(
            config: config,
            net: networkClient,
            tokens: tokenStore
        )
        self.oauthWeb = OAuthWebAuthenticator()

    }

    // MARK: Registration
    public func register(
        fname: String,
        lname: String,
        username: String,
        email: String,
        phone: String,
        password: String,
        roles: [String]
    ) async throws -> User? {
        let (_, user, _) = try await regService.register(
            fname: fname,
            lname: lname,
            username: username,
            email: email,
            phone: phone,
            password: password,
            roles: roles
        )
        return user
    }

    public func verifyEmail(token: String) async throws {
        _ = try await regService.verifyEmail(token: token)
    }

    // MARK: Login + OTP
    public func loginStart(
        identifier: String,
        password: String,
        rememberMe: Bool
    ) async throws -> (otpSentTo: String?, debugOTP: String?) {
        let (_, user, otpCode, _, maybeAccess) = try await loginService.login(
            identifier: identifier,
            password: password,
            rememberMe: rememberMe
        )  // login may return accessToken now :contentReference[oaicite:6]{index=6}

        if let token = maybeAccess {
            // Trusted device: token returned immediately (no OTP)
            try? tokens.save(Tokens(accessToken: token))
            if let u = user { currentUser = u }
            return (otpSentTo: nil, debugOTP: nil)
        } else {
            // New/untrusted device: OTP required
            return (otpSentTo: user?.email, debugOTP: otpCode)
        }
    }


    // MARK: Password Reset
    public func requestPasswordReset(email: String) async throws {
        _ = try await resetService.requestReset(email: email)
    }

    public func resetPassword(token: String, newPassword: String) async throws {
        _ = try await resetService.reset(token: token, newPassword: newPassword)
    }

    // MARK: Session
    public func refreshIfNeeded() async throws {
        let current = try tokens.load()
        _ = try await tokenService.refresh(using: current?.refreshToken)  // cookie flow ignores body
    }

    public func logout() async throws {
        if let access = try tokens.load()?.accessToken {
            _ = try await tokenService.logout(accessToken: access)
        }
        try? tokens.clear()
        currentUser = nil
    }

    // MARK: Microsoft — Built-in web OAuth
    public func socialLoginMicrosoft() async throws -> User {
        guard config.providers.microsoft?.enabled == true else { throw APIError.unauthorized }
        guard config.providers.microsoft?.useBuiltInWebOAuth == true else { throw APIError.unauthorized }

        // helpful fail-fast for host apps:
        try HostAppValidation.assertURLSchemePresent(expectedScheme: config.providers.microsoft!.redirectScheme)

        let cred = try await oauthWeb.authenticateMicrosoft(config: config)
        let (_, user, _) = try await socialService.exchange(credential: cred)
        guard let user else { throw APIError.unknown }
        currentUser = user
        return user
    }

    // MARK: Microsoft — BYOT (host app uses MSAL and passes an idToken)
    public func socialLoginMicrosoft(token idToken: String) async throws -> User {
        guard config.providers.microsoft?.enabled == true else { throw APIError.unauthorized }
        let cred = SocialCredential(provider: .microsoft, idToken: idToken)
        let (_, user, _) = try await socialService.exchange(credential: cred)
        guard let user else { throw APIError.unknown }
        currentUser = user
        return user
    }
}
