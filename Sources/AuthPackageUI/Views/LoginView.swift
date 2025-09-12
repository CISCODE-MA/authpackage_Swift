//
//  LoginView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

public struct LoginView: View {
    @Environment(\.authUIStyle) private var style
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject private var router: AuthUIRouter

    @State private var showError = false  // ADD

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
                    print("[AuthUI] Sign In tapped")  // ADD
                    Task {
                        await vm.login()
                        if let err = vm.errorMessage, !err.isEmpty {
                            print("[AuthUI] Login error: \(err)")  // ADD
                            showError = true  // ADD
                        } else {
                            print("[AuthUI] Login success")  // ADD
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

                NavigationLink(destination: PasswordResetRequestView()) {
                    Text("Forgot password?")
                }
            }

            if let error = vm.errorMessage, !error.isEmpty {
                Text(error).foregroundColor(.red).font(.footnote)
            }
        }
        .foregroundStyle(style.colors.text)
        .navigationTitle("")
        .alert(
            "Login failed",
            isPresented: $showError,
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(vm.errorMessage ?? "Unknown error")
            }
        )
    }
}
