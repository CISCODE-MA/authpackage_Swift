//
//  AuthPrimaryButton.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

#if canImport(SwiftUI)
    import SwiftUI

    public struct AuthPrimaryButton: View {
        let title: String
        let action: () -> Void
        var disabled: Bool = false
        var theme: AuthTheme = .init()

        public init(
            _ title: String,
            disabled: Bool = false,
            theme: AuthTheme = .init(),
            action: @escaping () -> Void
        ) {
            self.title = title
            self.disabled = disabled
            self.theme = theme
            self.action = action
        }

        public var body: some View {
            Button(action: action) {
                Text(title)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .disabled(disabled)
            .background(disabled ? Color.gray.opacity(0.2) : theme.primary)
            .foregroundColor(.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: theme.cornerRadius,
                    style: .continuous
                )
            )
            .shadow(radius: disabled ? 0 : 2)
        }
    }
#endif
