import SwiftUI

public struct ForgotPasswordView: View {
    @ObservedObject private var viewModel: ForgotPasswordViewModel

    public init(viewModel: ForgotPasswordViewModel) { self.viewModel = viewModel }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Forgot your password?")
                .font(.title2).bold()
            Text("Enter your email and we'll send a reset link.")
                .formCaption()

            GroupBox {
                TextField("Email", text: $viewModel.email)
#if os(iOS)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
#endif
                    .padding(.vertical, 4)
            }

            if let error = viewModel.errorMessage { InlineErrorView(message: error) }

            if viewModel.emailSent {
                Label("Email sent — check your inbox.", systemImage: "envelope.badge")
                    .foregroundStyle(.green)
            }

            AuthPrimaryButton(
                title: viewModel.isLoading ? "Sending…" : "Send reset link",
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.submit() }
            }
        }
        .padding(20)
        .frame(maxWidth: 480)
        .navigationTitle("Forgot Password")
        .background(.background)
    }
}
