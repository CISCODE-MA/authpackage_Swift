//
//  RegisterViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

@MainActor
public final class RegisterViewModel: ObservableObject {
    private let client: AuthClienting

    // Inputs
    @Published public var firstName: String = ""
    @Published public var lastName: String = ""
    @Published public var username: String = ""
    @Published public var email: String = ""
    @Published public var phone: String = ""
    @Published public var password: String = ""

    // Outputs
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil

    /// Host can observe and navigate to EmailVerificationView.
    public var onRegistered: (() -> Void)?

    public init(client: AuthClienting) {
        self.client = client
    }

    public func submit() async {
        errorMessage = nil
        guard validateInputs() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.register(
                firstName: firstName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                lastName: lastName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                username: username.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            onRegistered?()
        } catch {
            errorMessage =
                (error as? LocalizedError)?.errorDescription
                ?? "Something went wrong. Please try again."
        }
    }

    private func validateInputs() -> Bool {
        if firstName.isEmpty || lastName.isEmpty || username.isEmpty
            || email.isEmpty || password.isEmpty
        {
            errorMessage = "Please fill all required fields."
            return false
        }
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Enter a valid email."
            return false
        }
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters."
            return false
        }
        return true
    }
}
