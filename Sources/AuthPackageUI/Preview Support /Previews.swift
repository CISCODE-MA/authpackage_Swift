//
//  Previews.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

import SwiftUI

#if DEBUG
    struct AuthUI_Previews: PreviewProvider {
        static var previews: some View {
            let theme = AuthTheme()
            Group {
                NavigationView {
                    RegisterView(
                        viewModel: RegisterViewModel(client: MockAuthClient()),
                        theme: theme
                    )
                }
                NavigationView {
                    ForgotPasswordView(
                        viewModel: ForgotPasswordViewModel(
                            client: MockAuthClient()
                        ),
                        theme: theme
                    )
                }
                NavigationView {
                    ResetPasswordView(
                        viewModel: ResetPasswordViewModel(
                            client: MockAuthClient()
                        ),
                        theme: theme
                    )
                }
                NavigationView {
                    EmailVerificationView(
                        viewModel: EmailVerificationViewModel(
                            client: MockAuthClient()
                        ),
                        theme: theme
                    )
                }
            }
            .previewDisplayName("Light")
            .preferredColorScheme(.light)

            Group {
                NavigationView {
                    RegisterView(
                        viewModel: RegisterViewModel(client: MockAuthClient()),
                        theme: theme
                    )
                }
                NavigationView {
                    ForgotPasswordView(
                        viewModel: ForgotPasswordViewModel(
                            client: MockAuthClient()
                        ),
                        theme: theme
                    )
                }
                NavigationView {
                    ResetPasswordView(
                        viewModel: ResetPasswordViewModel(
                            client: MockAuthClient()
                        ),
                        theme: theme
                    )
                }
                NavigationView {
                    EmailVerificationView(
                        viewModel: EmailVerificationViewModel(
                            client: MockAuthClient()
                        ),
                        theme: theme
                    )
                }
            }
            .previewDisplayName("Dark")
            .preferredColorScheme(.dark)
        }
    }
#endif
