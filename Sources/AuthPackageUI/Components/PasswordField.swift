//
//  PasswordField.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//


import SwiftUI

public struct PasswordField: View {
    @Binding var text: String
    let placeholder: String
    let theme: AuthTheme
    @State private var isSecure = true

    public init(_ placeholder: String, text: Binding<String>, theme: AuthTheme) {
        self._text = text
        self.placeholder = placeholder
        self.theme = theme
    }

    public var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
#if os(iOS)
                    .textContentType(.newPassword)
#endif
            } else {
                TextField(placeholder, text: $text)
#if os(iOS)
                    .textContentType(.newPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
#endif
            }
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye" : "eye.slash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}
