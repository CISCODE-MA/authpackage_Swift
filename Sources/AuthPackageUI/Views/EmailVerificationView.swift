import SwiftUI

public struct EmailVerificationView: View {
    @ObservedObject private var viewModel: EmailVerificationViewModel

    public init(viewModel: EmailVerificationViewModel) { self.viewModel = viewModel }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Verify your email")
                .font(.title2).bold()
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

            if let error = viewModel.errorMessage { InlineErrorView(message: error) }

            if viewModel.isVerified {
                Label("Email verified!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

            AuthPrimaryButton(
                title: viewModel.isLoading ? "Verifying…" : "Verify",
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.verify() }
            }
        }
        .padding(20)
        .frame(maxWidth: 480)
        .navigationTitle("Email Verification")
        .background(.background)
    }
}
