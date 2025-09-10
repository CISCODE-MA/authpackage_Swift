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
    @Published public var firstName = ""
    @Published public var lastName = ""
    @Published public var username = ""
    @Published public var email = ""
    @Published public var phone = ""
    @Published public var password = ""

    // Outputs
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String? = nil

    // Per-field errors
    @Published public private(set) var emailError: String? = nil
    @Published public private(set) var passwordError: String? = nil
    @Published public private(set) var usernameError: String? = nil

    public var onRegistered: (() -> Void)?

    public init(client: AuthClienting) { self.client = client }

    public var canSubmit: Bool {
        validate(soft: true)
        return emailError == nil && passwordError == nil && usernameError == nil
            && !firstName.isEmpty && !lastName.isEmpty
    }

    public func submit() async {
        errorMessage = nil
        guard validate(soft: false) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.register(
                firstName: firstName.authTrimmed,
                lastName: lastName.authTrimmed,
                username: username.authTrimmed,
                email: email.authTrimmed,
                phone: phone.authTrimmed,
                password: password
            )
            #if os(iOS)
                Haptics.success()
            #endif
            onRegistered?()
        } catch {
            #if os(iOS)
                Haptics.error()
            #endif
            errorMessage =
                (error as? LocalizedError)?.errorDescription
                ?? "Something went wrong. Please try again."
        }
    }

    @discardableResult
    private func validate(soft: Bool) -> Bool {
        emailError = email.authIsValidEmail ? nil : "Enter a valid email."
        passwordError =
            password.count >= 8
            ? nil : "Password must be at least 8 characters."
        usernameError =
            username.count >= 3
            ? nil : "Username must be at least 3 characters."
        if !soft, firstName.isEmpty || lastName.isEmpty {
            errorMessage = "Please fill all required fields."
        }
        return emailError == nil && passwordError == nil && usernameError == nil
            && !firstName.isEmpty && !lastName.isEmpty
    }
}
