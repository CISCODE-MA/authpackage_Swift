//
//  PasswordResetRequestView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//
#if os(iOS)

import SwiftUI

public struct PasswordResetRequestView: View {
    @StateObject private var vm = AuthViewModel()

    public init() {}

    public var body: some View {
        Form {
            Section(header: Text("Reset your password")) {
                TextField("Email", text: $vm.resetEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button("Send reset email") {
                    Task { await vm.requestPasswordReset() }
                }
                .disabled(vm.resetEmail.isEmpty || vm.isLoading)
            }
            if let error = vm.errorMessage {
                Section { Text(error).foregroundStyle(.red) }
            }
            Section(footer: Text("You'll receive a link that opens the app at <scheme>://reset-password?token=…")) {
                EmptyView()
            }
        }
        .navigationTitle("Forgot Password")
    }
}
#endif
