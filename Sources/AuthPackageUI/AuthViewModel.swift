//
//  AuthUIViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

//
//  AuthViewModel.swift
//  AuthPackageUI
//

import AuthPackage
import AuthenticationServices
import SwiftUI

// MARK: - A Sendable wrapper around the core client existential
private struct UnsafeSendableClient: @unchecked Sendable {
    let value: AuthClientProtocol
}

// MARK: - Actor that owns the client and performs all calls on its executor
private actor AuthWorker {
    private let clientBox: UnsafeSendableClient

    init(clientBox: UnsafeSendableClient) { self.clientBox = clientBox }

    // STATE (no suspension)
    func hasAccessToken() -> Bool {
        (clientBox.value.tokens?.accessToken.isEmpty == false)
    }
    func accessToken() -> String? { clientBox.value.tokens?.accessToken }

    // CORE
    func login(email: String, password: String) async throws -> JWTClaims? {
        try await clientBox.value.login(email: email, password: password)
    }

    func logout() async throws {
        try await clientBox.value.logout()  // server logout + local clear (core)
    }

    func register(email: String, password: String, name: String?) async throws
        -> User
    {
        try await clientBox.value.register(
            email: email,
            password: password,
            name: name,
            roles: nil
        )
    }

    // PASSWORD RESET
    func requestPasswordReset(email: String, type: String) async throws -> String? {
        try await clientBox.value.requestPasswordReset(email: email, type: type)
    }

    func resetPassword(token: String, newPassword: String) async throws
        -> String?
    {
        try await clientBox.value.resetPassword(
            token: token,
            newPassword: newPassword
        )
    }

    // OAUTH — core API is @MainActor; call it on main actor
    @MainActor
    func loginWithMicrosoft(from anchor: ASPresentationAnchor) async throws
        -> JWTClaims?
    {
        try await clientBox.value.loginWithMicrosoft(from: anchor)
    }
}

// MARK: - ViewModel (MainActor)
@MainActor
public final class AuthViewModel: ObservableObject {
    // Form + UI state
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var isAuthenticated: Bool = false

    @Published public var resetEmail: String = ""
    @Published public var resetNewPassword: String = ""

    @Published public var registerEmail: String = ""
    @Published public var registerPassword: String = ""
    @Published public var registerName: String = ""

    @Published public var displayName: String? = nil

    private let router: AuthUIRouter
    private let worker: AuthWorker

    public init(router: AuthUIRouter = .shared) {
        self.router = router
        self.worker = AuthWorker(
            clientBox: UnsafeSendableClient(value: router.client)
        )
        refreshAuthState()
    }

    // MARK: Helpers

    private func clearAllForms() {
        email = ""
        password = ""
        resetEmail = ""
        resetNewPassword = ""
        registerEmail = ""
        registerPassword = ""
        registerName = ""
        errorMessage = nil
    }

    public func refreshAuthState() {
        Task { [weak self] in
            let authed = await self?.worker.hasAccessToken() ?? false
            await MainActor.run { self?.isAuthenticated = authed }
            await self?.updateDisplayNameFromAccessToken()
        }
    }

    // MARK: Login

    public func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            // Flip immediately and clear credentials
            self.isAuthenticated = true
            self.email = ""
            self.password = ""
            updateDisplayNameFromAccessToken()
            refreshAuthState()
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    // MARK: Logout

    public func logout() async {
        // Optimistic UI flip + clear fields/errors FIRST
        self.isAuthenticated = false
        self.displayName = nil
        clearAllForms()

        isLoading = true
        defer { isLoading = false }
        do {
            try await worker.logout()
            // Ensure we stay logged out
            refreshAuthState()
        } catch {
            // swallow logout noise to avoid showing errors on login screen
            // print("Logout error: \(error)")
        }
    }

    // MARK: Registration (returns success Bool; no auto-login)

    public func register() async -> Bool {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.register(
                email: registerEmail.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                password: registerPassword,
                name: registerName.isEmpty ? nil : registerName
            )
            // success → clear registration fields, stay unauthenticated
            registerEmail = ""
            registerPassword = ""
            registerName = ""
            errorMessage = nil
            return true
        } catch {
            errorMessage = userMessage(for: error)
            return false
        }
    }

    // MARK: Forgot / Reset

    public func requestPasswordReset() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.requestPasswordReset(email: resetEmail, type: "client")
            resetEmail = ""
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    public func confirmPasswordReset(using token: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.resetPassword(
                token: token,
                newPassword: resetNewPassword
            )
            resetNewPassword = ""
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    // MARK: Microsoft

    public func loginWithMicrosoft(anchor: ASPresentationAnchor) async {
        guard router.config.microsoftEnabled else { return }
        // optional HTTPS safety (uncomment if desired)
        // if router.config.baseURL.scheme?.lowercased() != "https" {
        //     errorMessage = "Microsoft sign-in requires HTTPS baseURL. Use ngrok in development."
        //     return
        // }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.loginWithMicrosoft(from: anchor)
            self.isAuthenticated = true
            updateDisplayNameFromAccessToken()
            refreshAuthState()
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    // MARK: Friendly error mapping

    private func userMessage(for error: Error) -> String {
        if let api = error as? APIError {
            switch api {
            case .unauthorized: return "Invalid email or password."
            case .notFound: return "Account not found."
            case .badRequest(let msg):
                return msg.isEmpty ? "Invalid request." : msg
            case .network: return "Network error. Check your connection."
            default: return "Something went wrong. Please try again."
            }
        }
        return (error as NSError).localizedDescription
    }

    // MARK: Display name

    private func updateDisplayNameFromAccessToken() {
        Task { [weak self] in
            guard let self else { return }
            let token = await self.worker.accessToken()
            let name = Self.extractDisplayName(fromJWT: token)
            await MainActor.run { self.displayName = name }
        }
    }

    private static func extractDisplayName(fromJWT jwt: String?) -> String? {
        guard let jwt, !jwt.isEmpty else { return nil }
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let raw = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded =
            raw + String(repeating: "=", count: (4 - raw.count % 4) % 4)
        guard let data = Data(base64Encoded: padded),
            let json = try? JSONSerialization.jsonObject(with: data)
                as? [String: Any]
        else { return nil }

        // common claim keys across providers/backends
        let keys = [
            "name", "given_name", "preferred_username", "email", "unique_name",
            "sub",
        ]
        for k in keys {
            if let v = json[k] as? String, !v.isEmpty { return v }
        }
        if let g = json["given_name"] as? String,
            let f = json["family_name"] as? String,
            !g.isEmpty || !f.isEmpty
        {
            return [g, f].filter { !$0.isEmpty }.joined(separator: " ")
        }
        return nil
    }
}
