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

    @FocusState private var focus: Field?
    enum Field { case fname, lname, username, email, phone, password }

    public init(viewModel: RegisterViewModel, theme: AuthTheme = .init()) {
        self.viewModel = viewModel
        self.theme = theme
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing) {
                Text("Create your account")
                    .font(.title2).bold()
                    .foregroundStyle(theme.text)

                Group {
                    AuthFormField(theme: theme, title: "Name") {
                        HStack {
                            TextField("First name", text: $viewModel.firstName)
                                #if os(iOS)
                                    .textContentType(.givenName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                #endif
                                .focused($focus, equals: .fname)
                            TextField("Last name", text: $viewModel.lastName)
                                #if os(iOS)
                                    .textContentType(.familyName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                #endif
                                .focused($focus, equals: .lname)
                        }
                    }

                    AuthFormField(
                        theme: theme,
                        title: "Username",
                        error: viewModel.usernameError
                    ) {
                        TextField("Username", text: $viewModel.username)
                            #if os(iOS)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            #endif
                            .focused($focus, equals: .username)
                    }

                    AuthFormField(
                        theme: theme,
                        title: "Email",
                        error: viewModel.emailError
                    ) {
                        TextField("Email", text: $viewModel.email)
                            #if os(iOS)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            #endif
                            .focused($focus, equals: .email)
                    }

                    AuthFormField(theme: theme, title: "Phone (optional)") {
                        TextField("Phone", text: $viewModel.phone)
                            #if os(iOS)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                            #endif
                            .focused($focus, equals: .phone)
                    }

                    AuthFormField(
                        theme: theme,
                        title: "Password",
                        error: viewModel.passwordError
                    ) {
                        PasswordField(
                            "Password",
                            text: $viewModel.password,
                            theme: theme
                        )
                        .focused($focus, equals: .password)
                    }

                    PasswordStrengthView(for: viewModel.password)
                }

                if let error = viewModel.errorMessage {
                    InlineErrorView(message: error)
                }

                VStack(spacing: 8) {
                    AuthPrimaryButton(
                        viewModel.isLoading ? "Creating…" : "Create Account",
                        disabled: !viewModel.canSubmit || viewModel.isLoading,
                        theme: theme
                    ) {
                        Task { await submitOrMove() }
                    }
                    .accessibilityIdentifier("register.primaryButton")

                    if viewModel.isLoading {
                        ProgressView().progressViewStyle(.circular)
                    }
                }

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
        .onSubmit { Task { await submitOrMove() } }
        #if os(iOS)
            .submitLabel(.next)
        #endif
        .onAppear { focus = .fname }
    }

    private func submitOrMove() async {
        switch focus {
        case .fname: focus = .lname
        case .lname: focus = .username
        case .username: focus = .email
        case .email: focus = .phone
        case .phone: focus = .password
        case .password, .none:
            await viewModel.submit()
        }
    }
}
