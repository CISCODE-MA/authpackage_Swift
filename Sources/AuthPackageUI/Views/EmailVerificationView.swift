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
    @FocusState private var focused: Bool

    public init(
        viewModel: EmailVerificationViewModel,
        theme: AuthTheme = .init()
    ) {
        self.viewModel = viewModel
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            Text("Verify your email").font(.title2).bold().foregroundStyle(
                theme.text
            )
            Text("Enter the verification token we sent to your email.")
                .formCaption()

            AuthFormField(theme: theme, title: "Verification token") {
                TextField("123456", text: $viewModel.token)
                    #if os(iOS)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    #endif
                    .focused($focused)
            }

            if let error = viewModel.errorMessage {
                InlineErrorView(message: error)
            }
            if viewModel.isVerified {
                Label("Email verified!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

            VStack(spacing: 8) {
                AuthPrimaryButton(
                    viewModel.isLoading ? "Verifying…" : "Verify",
                    disabled: !viewModel.canSubmit,
                    theme: theme
                ) { Task { await viewModel.verify() } }
                if viewModel.isLoading { ProgressView() }
            }
        }
        .padding(theme.spacing * 1.5)
        .frame(maxWidth: 480)
        .navigationTitle("Email Verification")
        .background(theme.background)
        .onAppear { focused = true }
    }
}
