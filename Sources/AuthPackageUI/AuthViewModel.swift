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

    func register(email: String, password: String, name: String?) async throws -> User {
        try await clientBox.value.register(email: email, password: password, name: name, roles: nil)
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
    
    @Published public var registerEmail: String = ""
    @Published public var registerPassword: String = ""
    @Published public var registerName: String = ""


    // Routing/config
    private let router: AuthUIRouter
    // Concurrency-safe worker that owns the client
    private let worker: AuthWorker

    public init(router: AuthUIRouter = .shared) {
        self.router = router
        self.worker = AuthWorker(
            clientBox: UnsafeSendableClient(value: router.client)
        )
        refreshAuthState()
    }

    public func refreshAuthState() {
        Task { [weak self] in
            let authed = await self?.worker.hasAccessToken() ?? false
            await MainActor.run { self?.isAuthenticated = authed }
        }
    }
    
    public func register() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.register(
                email: registerEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                password: registerPassword,
                name: registerName.isEmpty ? nil : registerName
            )
            // many backends auto-login on register and return tokens;
            // if not, you can optionally call login() here.
            refreshAuthState()
            // Optional: Auto-login using the just-entered credentials if your backend doesn't sign in:
            if !isAuthenticated {
                _ = try await worker.login(email: registerEmail, password: registerPassword)
                self.isAuthenticated = true
                refreshAuthState()
            }
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    public func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            print("[AuthUI] Calling core login(email:\(email))")
            _ = try await worker.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            print("[AuthUI] Core login returned OK")
            // Flip immediately so the parent view transitions now.
            self.isAuthenticated = true
            // Still reconcile with the actual token store.
            refreshAuthState()
        } catch {
            let msg = (error as NSError).localizedDescription
            print("[AuthUI] Core login threw: \(msg)")
            errorMessage = msg
        }
    }

    public func logout() async {
        // Optimistic flip: go back to login right away
        self.isAuthenticated = false

        isLoading = true
        defer { isLoading = false }
        do {
            try await worker.logout()
            // Re-check in case the core/store already cleared/persisted differently
            refreshAuthState()
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    public func requestPasswordReset() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.requestPasswordReset(email: resetEmail)
        } catch {
            errorMessage = (error as NSError).localizedDescription
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
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    public func loginWithMicrosoft(anchor: ASPresentationAnchor) async {
        guard router.config.microsoftEnabled else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await worker.loginWithMicrosoft(from: anchor)
            refreshAuthState()
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }
}
