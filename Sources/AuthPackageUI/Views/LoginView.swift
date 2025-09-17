//
//  LoginView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//
#if os(iOS)
    import AuthenticationServices
    import SwiftUI
    #if canImport(UIKit)
        import UIKit
    #endif

    public struct LoginView: View {
        @Environment(\.authUIStyle) private var style
        @EnvironmentObject private var router: AuthUIRouter
        @ObservedObject private var vm: AuthViewModel

        @State private var anchorWindow: ASPresentationAnchor?
        @State private var showErrorAlert = false

        public init(vm: AuthViewModel) {
            self._vm = ObservedObject(initialValue: vm)
        }

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

                    Button {
                        Task {
                            await vm.login()
                            if let err = vm.errorMessage, !err.isEmpty {
                                showErrorAlert = true
                            }
                        }
                    } label: {
                        HStack {
                            if vm.isLoading { ProgressView() }
                            Text("Sign In")
                        }
                    }
                    .primaryButton()
                    .disabled(
                        vm.email.isEmpty || vm.password.isEmpty || vm.isLoading
                    )

                    // Microsoft
                    if router.config.microsoftEnabled {
                        Button {
                            Task { @MainActor in
                                let anchor = anchorWindow ?? keyWindow()
                                if let anchor {
                                    await vm.loginWithMicrosoft(anchor: anchor)
                                } else {
                                    vm.errorMessage =
                                        "Unable to present Microsoft sign-in (no window anchor)."
                                    showErrorAlert = true
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "m.circle")
                                Text("Sign in with Microsoft")
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    // Google (NEW)
                    if router.config.googleEnabled {
                        Button {
                            Task { @MainActor in
                                let anchor = anchorWindow ?? keyWindow()
                                if let anchor {
                                    await vm.loginWithGoogle(anchor: anchor)
                                } else {
                                    vm.errorMessage =
                                        "Unable to present Google sign-in (no window anchor)."
                                    showErrorAlert = true
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "g.circle")
                                Text("Sign in with Google")
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    // Facebook (NEW)
                    if router.config.facebookEnabled {
                        Button {
                            Task { @MainActor in
                                let anchor = anchorWindow ?? keyWindow()
                                if let anchor {
                                    await vm.loginWithFacebook(anchor: anchor)
                                } else {
                                    vm.errorMessage =
                                        "Unable to present Facebook sign-in (no window anchor)."
                                    showErrorAlert = true
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "f.cursive.circle")
                                Text("Sign in with Facebook")
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    NavigationLink(destination: PasswordResetRequestView()) {
                        Text("Forgot password?")
                    }
                }

                if let error = vm.errorMessage, !error.isEmpty {
                    Text(error).foregroundColor(.red).font(.footnote)
                }

                NavigationLink(destination: PasswordResetRequestView()) {
                    Text("Forgot password?")
                }
                NavigationLink(destination: RegistrationView(vm: vm)) {
                    Text("Don’t have an account? Create one")
                }
            }
            .foregroundStyle(style.colors.text)
            .navigationTitle("")
            .background(WindowReader(anchor: $anchorWindow))
            .alert("Login failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "Unknown error")
            }
        }
    }

    #if canImport(UIKit)
        @MainActor

        // Finds a good presentation anchor if our local capture fails.
        private func keyWindow() -> ASPresentationAnchor? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }

        // Reads the hosting view’s window to use as an anchor.
        private struct WindowReader: UIViewRepresentable {
            @Binding var anchor: ASPresentationAnchor?

            func makeUIView(context: Context) -> UIView {
                let v = UIView(frame: .zero)
                DispatchQueue.main.async { [weak v] in anchor = v?.window }
                return v
            }
            func updateUIView(_ uiView: UIView, context: Context) {}
        }
    #else
        private func keyWindow() -> ASPresentationAnchor? { nil }
        private struct WindowReader: View {
            @Binding var anchor: ASPresentationAnchor?
            var body: some View { Color.clear }
        }
    #endif
#endif
