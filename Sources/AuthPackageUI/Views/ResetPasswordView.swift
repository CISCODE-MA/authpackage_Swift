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

    public init(viewModel: ResetPasswordViewModel, theme: AuthTheme = .init()) {
        self.viewModel = viewModel
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reset your password")
                .font(.title2).bold()
                .foregroundStyle(theme.text)

            Text("Paste the token from your email and choose a new password.")
                .formCaption()

            GroupBox {
                VStack(spacing: 12) {
                    TextField("Token", text: $viewModel.token)
                        #if os(iOS)
                            .textContentType(.oneTimeCode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        #endif
                    SecureField("New password", text: $viewModel.newPassword)
                        #if os(iOS)
                            .textContentType(.newPassword)
                        #endif
                }
                .padding(.vertical, 4)
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

            if viewModel.didReset {
                Label(
                    "Password successfully reset.",
                    systemImage: "checkmark.seal.fill"
                )
                .foregroundStyle(.green)
            }

            AuthPrimaryButton(
                viewModel.isLoading ? "Resetting…" : "Reset password",
                disabled: viewModel.isLoading,
                theme: theme
            ) {
                Task { await viewModel.submit() }
            }
        }
        .padding(theme.spacing * 1.5)
        .frame(maxWidth: 520)
        .navigationTitle("Reset Password")
        .background(theme.background)
    }
}
