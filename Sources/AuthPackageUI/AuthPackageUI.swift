//
//  AuthPackageUI.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//
#if os(iOS)

    @preconcurrency import AuthPackage
    import SwiftUI

    public enum AuthPackageUI {}

    extension AuthPackageUI {
        @MainActor
        public static func makeRoot(
            config: AuthUIConfig,
            client: AuthClientProtocol
        ) -> some View {
            _AuthUIRoot(config: config, client: client)
        }
    }

    /// Private root view that configures the router in init (not inside a ViewBuilder)
    @MainActor
    private struct _AuthUIRoot: View {
        let config: AuthUIConfig
        @StateObject private var router = AuthUIRouter.shared

        init(config: AuthUIConfig, client: AuthClientProtocol) {
            self.config = config
            AuthUIRouter.shared.configure(config: config, client: client)
        }

        @ViewBuilder
        private var content: some View {
            AuthFlowView()
                .environmentObject(router)
                .environment(\.authUIStyle, config.style)
        }

        var body: some View {
            Group {
                if #available(iOS 16.0, *) {
                    AnyView(
                        NavigationStack { content }
                    )
                } else {
                    AnyView(
                        NavigationView { content }
                            .navigationViewStyle(.stack)
                    )
                }
            }
        }
    }
#endif
