#if canImport(SwiftUI)
import SwiftUI

public struct LoginView: View {
    @StateObject var vm: LoginViewModel
    var theme: AuthTheme

    public init(viewModel: LoginViewModel, theme: AuthTheme = .init()) {
        _vm = StateObject(wrappedValue: viewModel)
        self.theme = theme
    }

    public var body: some View {
        VStack(spacing: theme.spacing) {
            Text("Sign In")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                TextField("Email or Username", text: $vm.identifier)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))

                SecureField("Password", text: $vm.password)
                    .textContentType(.password)
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))

                Toggle("Remember me", isOn: $vm.rememberMe)
            }

            if let error = vm.error {
                Text(error).foregroundColor(theme.danger)
            }

            AuthPrimaryButton(vm.isLoading ? "Signing In…" : "Sign In", disabled: vm.isLoading) {
                Task { await vm.submit() }
            }

            if let sent = vm.otpSentTo {
                Text("OTP sent to \(sent)").font(.footnote).foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(theme.background.ignoresSafeArea())
    }
}
#endif
