//
//  EmailVerificationViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import Foundation

@MainActor
public final class EmailVerificationViewModel: ObservableObject {
    private let client: AuthClienting

    @Published public var token: String = ""

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    @Published public private(set) var isVerified: Bool = false

    public init(client: AuthClienting) {
        self.client = client
    }

    public func verify() async {
        errorMessage = nil
        isVerified = false
        guard !token.isEmpty else {
            errorMessage = "Token required."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.verifyEmail(
                token: token.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isVerified = true
        } catch {
            errorMessage =
                (error as? LocalizedError)?.errorDescription
                ?? "Verification failed."
        }
    }
}
