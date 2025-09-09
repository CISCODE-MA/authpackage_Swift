//
//  LoginViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

#if canImport(SwiftUI)
    import Foundation
    import AuthPackage

    @MainActor
    public final class LoginViewModel: ObservableObject {
        @preconcurrency
        nonisolated(unsafe) private let client: AuthClientProtocol
        
        @Published public var identifier: String = ""
        @Published public var password: String = ""
        @Published public var rememberMe: Bool = true

        @Published public var isLoading = false
        @Published public var errorMessage: String?
        @Published public var otpSentTo: String?
        @Published public var debugOTP: String?

        public init(client: AuthClientProtocol) {
            self.client = client
        }

        public func submit() async {
            isLoading = true
            defer { isLoading = false }

            do {
                let res = try await client.loginStart(
                    identifier: identifier,
                    password: password,
                    rememberMe: rememberMe
                )
                otpSentTo = res.otpSentTo
                debugOTP = res.debugOTP
                errorMessage = nil
            } catch {
                errorMessage = String(describing: error)
            }
        }
    }
#endif
