import SwiftUI

public struct ResetPasswordView: View {
    @ObservedObject private var viewModel: ResetPasswordViewModel

    public init(viewModel: ResetPasswordViewModel) { self.viewModel = viewModel }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reset your password")
                .font(.title2).bold()
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

            if let error = viewModel.errorMessage { InlineErrorView(message: error) }

            if viewModel.didReset {
                Label("Password successfully reset.", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

            AuthPrimaryButton(
                title: viewModel.isLoading ? "Resetting…" : "Reset password",
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.submit() }
            }
        }
        .padding(20)
        .frame(maxWidth: 520)
        .navigationTitle("Reset Password")
        .background(.background)
    }
}
