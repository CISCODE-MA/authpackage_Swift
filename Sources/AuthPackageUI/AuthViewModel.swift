//
//  AuthUIViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

// keep the normal import (no @preconcurrency) so we don't mask problems
import AuthPackage
import AuthenticationServices
import SwiftUI

// MARK: - A Sendable wrapper around the core client existential
// We promise the value will only be touched inside our actor.
private struct UnsafeSendableClient: @unchecked Sendable {
    let value: AuthClientProtocol
}

// MARK: - Actor that owns the client and performs all calls on its executor
private actor AuthWorker {
    private let clientBox: UnsafeSendableClient

    init(clientBox: UnsafeSendableClient) {
        self.clientBox = clientBox
    }

    // STATE (no suspension)
    func hasAccessToken() -> Bool {
        (clientBox.value.tokens?.accessToken.isEmpty == false)
    }

    // CORE
    func login(email: String, password: String) async throws -> JWTClaims? {
        try await clientBox.value.login(email: email, password: password)
    }

    func logout() async throws {
        try await clientBox.value.logout()
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
    func requestPasswordReset(email: String) async throws -> String? {
        try await clientBox.value.requestPasswordReset(email: email)
    }

    func resetPassword(token: String, newPassword: String) async throws
        -> String?
    {
        try await clientBox.value.resetPassword(
            token: token,
            newPassword: newPassword
        )
    }

    // OAUTH (your core API is @MainActor per README; call it on main actor)
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

    // ✅ ADD: registration fields
    @Published public var registerEmail: String = ""
    @Published public var registerPassword: String = ""
    @Published public var registerName: String = ""

    private let router: AuthUIRouter
    private let worker: AuthWorker

    public init(router: AuthUIRouter = .shared) {
        self.router = router
        self.worker = AuthWorker(
            clientBox: UnsafeSendableClient(value: router.client)
        )
        refreshAuthState()
    }

    // Helper: clear all input fields + error
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
            // ✅ flip immediately and clear credentials
            self.isAuthenticated = true
            self.email = ""
            self.password = ""
            refreshAuthState()
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    // MARK: Logout
    public func logout() async {
        // ✅ optimistic UI flip + clear fields/errors FIRST
        self.isAuthenticated = false
        clearAllForms()

        isLoading = true
        defer { isLoading = false }
        do {
            try await worker.logout()  // server logout + token clear (core) :contentReference[oaicite:1]{index=1}
            // ✅ ensure we stay logged out
            refreshAuthState()
        } catch {
            // ✅ swallow server noise here (401/expired session etc.) and do NOT show on login screen
            // If you want to surface it for debugging, log it instead of setting errorMessage.
            // print("Logout error: \(error)")
        }
    }

    // MARK: Registration (returns success Bool; no auto-login)
    public func register() async -> Bool {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            // add this method in AuthWorker if you don't have it yet:
            // func register(email: String, password: String, name: String?) async throws -> User
            _ = try await worker.register(
                email: registerEmail.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                password: registerPassword,
                name: registerName.isEmpty ? nil : registerName
            )
            // ✅ on success: clear registration fields and return to Login
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
            _ = try await worker.requestPasswordReset(email: resetEmail)
            // optional: clear the field on success
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
            // optional: clear field on success
            resetNewPassword = ""
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    public func loginWithMicrosoft(anchor: ASPresentationAnchor) async {
        guard router.config.microsoftEnabled else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.loginWithMicrosoft(from: anchor)
            self.isAuthenticated = true
            refreshAuthState()
        } catch {
            errorMessage = userMessage(for: error)
        }
    }

    // MARK: Friendly error mapping (instead of "The operation couldn’t be completed...")
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
}
