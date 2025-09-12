//
//  RegistrationView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import SwiftUI

public struct RegistrationView: View {
    @Environment(\.authUIStyle) private var style
    @ObservedObject private var vm: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false

    public init(vm: AuthViewModel) {
        self._vm = ObservedObject(initialValue: vm)
    }

    public var body: some View {
        Form {
            Section(header: Text("Create your account")) {
                TextField("Email", text: $vm.registerEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $vm.registerPassword)
                    .textContentType(.newPassword)

                TextField("Full name (optional)", text: $vm.registerName)
                    .textContentType(.name)
            }

            Section {
                Button {
                    Task {
                        let ok = await vm.register()
                        if ok {
                            showSuccessAlert = true
                        } else {
                            showErrorAlert = true
                        }
                    }
                } label: {
                    HStack {
                        if vm.isLoading { ProgressView() }
                        Text("Create Account")
                    }
                }
                .disabled(
                    vm.registerEmail.isEmpty || vm.registerPassword.isEmpty
                        || vm.isLoading
                )
            }
        }
        .navigationTitle("Sign Up")
        .tint(style.colors.primary)
        .alert("Sign up failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "Something went wrong. Please try again.")
        }
        .alert("Account created", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }  // ← back to Login after success
        } message: {
            Text("Your account was created successfully. Please sign in.")
        }
    }
}
