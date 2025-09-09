//
//  OTPView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

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
                    #if os(iOS)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                    #endif
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                    )

                if let error = vm.errorMessage {
                    Text(error).foregroundColor(theme.danger)
                }

                AuthPrimaryButton(
                    vm.isLoading ? "Signing In…" : "Sign In",
                    disabled: vm.isLoading
                ) {
                    Task { @MainActor in await vm.verify() } 
                }

                if let user = vm.user {
                    Text("Welcome, \(user.fullname?.fname ?? "User")")
                        .font(.headline)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .background(theme.background.ignoresSafeArea())
        }
    }
#endif
