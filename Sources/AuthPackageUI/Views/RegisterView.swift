//
//  RegisterView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import SwiftUI

public struct RegisterView: View {
    @ObservedObject private var viewModel: RegisterViewModel
    private var theme: AuthTheme

    public init(viewModel: RegisterViewModel, theme: AuthTheme = .init()) {
        self.viewModel = viewModel
        self.theme = theme
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create your account")
                    .font(.title2).bold()
                    .foregroundStyle(theme.text)

                GroupBox {
                    VStack(spacing: 12) {
                        HStack {
                            TextField("First name", text: $viewModel.firstName)
                                #if os(iOS)
                                    .textContentType(.givenName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                #endif
                            TextField("Last name", text: $viewModel.lastName)
                                #if os(iOS)
                                    .textContentType(.familyName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                #endif
                        }

                        TextField("Username", text: $viewModel.username)
                            #if os(iOS)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            #endif

                        TextField("Email", text: $viewModel.email)
                            #if os(iOS)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            #endif

                        TextField("Phone (optional)", text: $viewModel.phone)
                            #if os(iOS)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                            #endif

                        SecureField("Password", text: $viewModel.password)
                            #if os(iOS)
                                .textContentType(.newPassword)
                            #endif
                    }
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: theme.cornerRadius,
                        style: .continuous
                    )
                )

                if let error = viewModel.errorMessage {
                    InlineErrorView(message: error)
                }

                AuthPrimaryButton(
                    viewModel.isLoading ? "Creating…" : "Create Account",
                    disabled: viewModel.isLoading,
                    theme: theme
                ) {
                    Task { await viewModel.submit() }
                }
                .accessibilityIdentifier("register.primaryButton")

                Text("By continuing you agree to our terms and privacy policy.")
                    .formCaption()
                    .foregroundStyle(.secondary)
            }
            .padding(theme.spacing * 1.5)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Register")
        .background(theme.background)
    }
}
