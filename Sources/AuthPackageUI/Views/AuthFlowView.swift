//
//  AuthFlowView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import SwiftUI

public struct AuthFlowView: View {
    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject private var router: AuthUIRouter
    @Environment(\.authUIStyle) private var style
    @Environment(\.openURL) private var openURL  // ADD

    public init() {}

    public var body: some View {
        ZStack {
            style.colors.background.ignoresSafeArea()
            Group {
                if vm.isAuthenticated {
                    PostLoginView(
                        vm: vm,
                        onLogout: { Task { await vm.logout() } }
                    )
                } else if let token = router.pendingResetToken {
                    PasswordResetConfirmView(token: token) {
                        router.pendingResetToken = nil
                    }
                } else {
                    LoginView(vm: vm)
                }
            }
            .padding()
        }
        .tint(style.colors.primary)
        .onOpenURL { url in
            if router.handle(url: url) {
                Task { @MainActor in vm.refreshAuthState() }
            }
        }
        .onAppear { vm.refreshAuthState() }
        // NEW: if a post-login deeplink is provided, open it right away
        .onChange(of: vm.isAuthenticated) { authed in
            guard authed, let url = router.config.postLoginDeeplink else {
                return
            }
            openURL(url)
        }
        .animation(.easeInOut, value: vm.isAuthenticated)
        .overlay(alignment: .top) {
            NoticeBanner(notice: $vm.notice)
        }
        .overlay {
            LoadingOverlay(isVisible: vm.isLoading)
        }
    }
}
