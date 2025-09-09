#if canImport(SwiftUI)
import SwiftUI

public struct OTPView: View {
    @StateObject var vm: OTPViewModel
    var theme: AuthTheme

    public init(viewModel: OTPViewModel, theme: AuthTheme = .init()) {
        _vm = StateObject(wrappedValue: viewModel)
        self.theme = theme
    }

    public var body: some View {
        VStack(spacing: theme.spacing) {
            Text("Enter OTP").font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("6-digit code", text: $vm.otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding()
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))

            if let error = vm.error {
                Text(error).foregroundColor(theme.danger)
            }

            AuthPrimaryButton(vm.isLoading ? "Verifying…" : "Verify", disabled: vm.isLoading || vm.otp.isEmpty) {
                Task { await vm.verify() }
            }

            if let user = vm.user {
                Text("Welcome, \(user.fullname.fname)")
                    .font(.headline)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(theme.background.ignoresSafeArea())
    }
}
#endif
