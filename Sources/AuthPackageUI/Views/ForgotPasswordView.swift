//
//  ForgotPasswordView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import SwiftUI

public struct ForgotPasswordView: View {
    @ObservedObject private var viewModel: ForgotPasswordViewModel
    private var theme: AuthTheme
    @FocusState private var focused: Bool

    public init(viewModel: ForgotPasswordViewModel, theme: AuthTheme = .init())
    {
        self.viewModel = viewModel
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Forgot your password?").font(.title2).bold().foregroundStyle(
                theme.text
            )
            Text("Enter your email and we'll send a reset link.").formCaption()

            AuthFormField(theme: theme, title: "Email") {
                TextField("Email", text: $viewModel.email)
                    #if os(iOS)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    #endif
                    .focused($focused)
            }

            if let error = viewModel.errorMessage {
                InlineErrorView(message: error)
            }
            if viewModel.emailSent {
                Label(
                    "Email sent — check your inbox.",
                    systemImage: "envelope.badge"
                )
                .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                AuthPrimaryButton(
                    viewModel.isLoading ? "Sending…" : "Send reset link",
                    disabled: !viewModel.canSubmit,
                    theme: theme
                ) { Task { await viewModel.submit() } }
                if viewModel.isLoading { ProgressView() }
            }
        }
        .padding(theme.spacing * 1.5)
        .frame(maxWidth: 480)
        .navigationTitle("Forgot Password")
        .background(theme.background)
        .onAppear { focused = true }
    }
}
