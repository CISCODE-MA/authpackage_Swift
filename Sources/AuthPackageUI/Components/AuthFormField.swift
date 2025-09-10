//
//  AuthFormField.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//


import SwiftUI

public struct AuthFormField<Content: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    let theme: AuthTheme
    let title: String?
    let help: String?
    let error: String?
    @ViewBuilder let content: Content

    public init(
        theme: AuthTheme,
        title: String? = nil,
        help: String? = nil,
        error: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.title = title
        self.help = help
        self.error = error
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title { Text(title).font(.subheadline).foregroundStyle(.secondary) }
            content
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                        .strokeBorder(error == nil ? .mint : theme.danger, lineWidth: 1)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
                )
            if let error { Text(error).font(.footnote).foregroundStyle(theme.danger) }
            else if let help { Text(help).font(.footnote).foregroundStyle(.secondary) }
        }
    }
}
