import SwiftUI

public struct RegisterView: View {
    @ObservedObject private var viewModel: RegisterViewModel

    public init(viewModel: RegisterViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create your account")
                    .font(.title2).bold()

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

                if let error = viewModel.errorMessage { InlineErrorView(message: error) }

                AuthPrimaryButton(
                    title: viewModel.isLoading ? "Creating…" : "Create Account",
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.submit() }
                }
                .accessibilityIdentifier("register.primaryButton")

                Text("By continuing you agree to our terms and privacy policy.")
                    .formCaption()
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Register")
        .background(.background)
    }
}
