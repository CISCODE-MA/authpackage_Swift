//
//  ForgotPasswordViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

@MainActor
public final class ForgotPasswordViewModel: ObservableObject {
    private let client: AuthClienting

    @Published public var email: String = ""

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    @Published public private(set) var emailSent: Bool = false

    public init(client: AuthClienting) {
        self.client = client
    }

    public func submit() async {
        errorMessage = nil
        emailSent = false
        guard email.contains("@"), email.contains(".") else {
            errorMessage = "Enter a valid email."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.requestPasswordReset(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            emailSent = true
        } catch {
            errorMessage =
                (error as? LocalizedError)?.errorDescription
                ?? "Could not send reset email."
        }
    }
}
