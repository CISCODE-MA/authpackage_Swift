//
//  ResetPasswordView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//
import SwiftUI

public struct ResetPasswordView: View {
    @ObservedObject private var viewModel: ResetPasswordViewModel
    private var theme: AuthTheme
    @FocusState private var focusPwd: Bool
    @FocusState private var focusToken: Bool

    public init(viewModel: ResetPasswordViewModel, theme: AuthTheme = .init()) {
        self.viewModel = viewModel
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Reset your password").font(.title2).bold().foregroundStyle(
                theme.text
            )
            Text("Paste the token from your email and choose a new password.")
                .formCaption()

            AuthFormField(theme: theme, title: "Token") {
                TextField("Token", text: $viewModel.token)
                    #if os(iOS)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    #endif
                    .focused($focusToken)
            }

            AuthFormField(theme: theme, title: "New password") {
                PasswordField(
                    "New password",
                    text: $viewModel.newPassword,
                    theme: theme
                )
                .focused($focusPwd)
            }

            PasswordStrengthView(for: viewModel.newPassword)

            if let error = viewModel.errorMessage {
                InlineErrorView(message: error)
            }
            if viewModel.didReset {
                Label(
                    "Password successfully reset.",
                    systemImage: "checkmark.seal.fill"
                )
                .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                AuthPrimaryButton(
                    viewModel.isLoading ? "Resetting…" : "Reset password",
                    disabled: !viewModel.canSubmit,
                    theme: theme
                ) { Task { await viewModel.submit() } }
                if viewModel.isLoading { ProgressView() }
            }
        }
        .padding(theme.spacing * 1.5)
        .frame(maxWidth: 520)
        .navigationTitle("Reset Password")
        .background(theme.background)
        .onAppear { focusToken = true }
    }
}
