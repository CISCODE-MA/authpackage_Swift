//
//  PasswordResetConfirmView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//
#if os(iOS)

    import SwiftUI

    public struct PasswordResetConfirmView: View {
        @StateObject private var vm = AuthViewModel()
        private let token: String
        private let onComplete: () -> Void

        public init(token: String, onComplete: @escaping () -> Void) {
            self.token = token
            self.onComplete = onComplete
        }

        public var body: some View {
            Form {
                Section(header: Text("Create a new password")) {
                    SecureField("New password", text: $vm.resetNewPassword)
                        .textContentType(.newPassword)
                    Button("Update password") {
                        Task {
                            await vm.confirmPasswordReset(using: token)
                            onComplete()
                        }
                    }
                    .disabled(vm.resetNewPassword.isEmpty || vm.isLoading)
                }
                if let error = vm.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Reset Password")
        }
    }
#endif
