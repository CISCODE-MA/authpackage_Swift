//
//  EmailVerificationView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import SwiftUI

public struct EmailVerificationView: View {
    @ObservedObject private var viewModel: EmailVerificationViewModel
    private var theme: AuthTheme

    public init(
        viewModel: EmailVerificationViewModel,
        theme: AuthTheme = .init()
    ) {
        self.viewModel = viewModel
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Verify your email")
                .font(.title2).bold()
                .foregroundStyle(theme.text)

            Text("Enter the verification token we sent to your email.")
                .formCaption()

            GroupBox {
                TextField("Verification token", text: $viewModel.token)
                    #if os(iOS)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    #endif
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

            if viewModel.isVerified {
                Label("Email verified!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

            AuthPrimaryButton(
                viewModel.isLoading ? "Verifying…" : "Verify",
                disabled: viewModel.isLoading,
                theme: theme
            ) {
                Task { await viewModel.verify() }
            }
        }
        .padding(theme.spacing * 1.5)
        .frame(maxWidth: 480)
        .navigationTitle("Email Verification")
        .background(theme.background)
    }
}
