//
//  AuthFlowView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import SwiftUI

public struct AuthFlowView: View {
    @EnvironmentObject private var router: AuthUIRouter
    @Environment(\.authUIStyle) private var style
    @StateObject private var vm = AuthViewModel()

    public init() {}

    public var body: some View {
        ZStack {
            style.colors.background.ignoresSafeArea()
            Group {
                if vm.isAuthenticated {
                    PostLoginView(onLogout: { Task { await vm.logout() } })
                } else if let token = router.pendingResetToken {
                    PasswordResetConfirmView(token: token) {
                        router.pendingResetToken = nil
                    }
                } else {
                    LoginView()
                }
            }
            .padding()
        }
        .onOpenURL { url in
            if router.handle(url: url) {
                Task { @MainActor in vm.refreshAuthState() }
            }
        }
        .animation(.easeInOut, value: vm.isAuthenticated)
    }
}
