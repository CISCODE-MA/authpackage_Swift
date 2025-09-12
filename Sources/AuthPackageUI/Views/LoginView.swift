//
//  LoginView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import SwiftUI
import AuthenticationServices

public struct LoginView: View {
    @Environment(\.authUIStyle) private var style
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject private var router: AuthUIRouter

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: style.metrics.spacing) {
            Text("Welcome").authTitle()

            VStack(spacing: style.metrics.spacing) {
                TextField("Email", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .fieldBackground()

                SecureField("Password", text: $vm.password)
                    .textContentType(.password)
                    .fieldBackground()

                Button { Task { await vm.login() } } label: {
                    HStack { if vm.isLoading { ProgressView() }; Text("Sign In") }
                }
                .primaryButton()
                .disabled(vm.email.isEmpty || vm.password.isEmpty || vm.isLoading)

                if router.config.microsoftEnabled {
                    SignInWithMicrosoftButton { anchor in
                        Task { await vm.loginWithMicrosoft(anchor: anchor) }
                    }
                }

                NavigationLink(destination: PasswordResetRequestView()) {
                    Text("Forgot password?")
                }
            }

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }
        }
        .foregroundStyle(style.colors.text)
        .navigationTitle("")
    }
}

private struct SignInWithMicrosoftButton: View {
    var action: (ASPresentationAnchor) -> Void
    @State private var window: ASPresentationAnchor?

    var body: some View {
        Button {
            if let w = window { action(w) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "m.circle")
                Text("Sign in with Microsoft")
            }
        }
        .buttonStyle(.bordered)
        .background(WindowReader(anchor: $window))
    }
}

/// Finds the current presentation anchor for ASWebAuthenticationSession.
private struct WindowReader: UIViewRepresentable {
    @Binding var anchor: ASPresentationAnchor?

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        DispatchQueue.main.async { [weak v] in anchor = v?.window }
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
