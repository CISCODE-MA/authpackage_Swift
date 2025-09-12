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
                        await vm.register()
                        if vm.isAuthenticated { dismiss() }
                    }
                } label: {
                    HStack {
                        if vm.isLoading { ProgressView() }
                        Text("Create Account")
                    }
                }
                .disabled(vm.registerEmail.isEmpty || vm.registerPassword.isEmpty || vm.isLoading)
            }

            if let error = vm.errorMessage, !error.isEmpty {
                Section(footer: Text(error).foregroundStyle(.red)) { EmptyView() }
            }
        }
        .navigationTitle("Sign Up")
        
        NavigationLink(destination: LoginView(vm: vm)) {
            Text("Already have an account? Sign back in")
        }
    }
}
