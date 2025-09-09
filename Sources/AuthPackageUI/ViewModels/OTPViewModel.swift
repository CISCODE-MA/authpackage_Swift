//
//  OTPViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

#if canImport(SwiftUI)
    import Foundation
    import AuthPackage

    @MainActor
    public final class OTPViewModel: ObservableObject {
        @preconcurrency
        nonisolated(unsafe) private let client: AuthClientProtocol

        private let identifier: String

        @Published public var otp: String = ""
        @Published public var isLoading = false
        @Published public var errorMessage: String?
        @Published public var user: User?

        public init(client: AuthClientProtocol, identifier: String) {
            self.client = client
            self.identifier = identifier
        }

        public func verify() async {
            isLoading = true
            defer { isLoading = false }

            do {
                let u = try await client.verifyOTP(
                    identifier: identifier,
                    otp: otp
                )
                user = u
                errorMessage = nil
            } catch {
                errorMessage = String(describing: error)
            }
        }
    }
#endif
