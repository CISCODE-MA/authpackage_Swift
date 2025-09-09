//
//  ResetPasswordViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

@MainActor
public final class ResetPasswordViewModel: ObservableObject {
    private let client: AuthClienting

    @Published public var token: String = ""
    @Published public var newPassword: String = ""

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    @Published public private(set) var didReset: Bool = false

    public init(client: AuthClienting) {
        self.client = client
    }

    public var canSubmit: Bool {
        !token.isEmpty && newPassword.count >= 8 && !isLoading
    }

    public func submit() async {
        errorMessage = nil
        didReset = false
        guard canSubmit else {
            errorMessage =
                token.isEmpty
                ? "Token required." : "Password must be at least 8 characters."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.resetPassword(
                token: token,
                newPassword: newPassword
            )
            didReset = true
            #if os(iOS)
                Haptics.success()
            #endif
        } catch {
            errorMessage =
                (error as? LocalizedError)?.errorDescription
                ?? "Could not reset password."
            #if os(iOS)
                Haptics.error()
            #endif
        }
    }
}
