//
//  Components.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import SwiftUI

struct PrimaryButton: ViewModifier {
    @Environment(\.authUIStyle) private var style
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(style.colors.primary)
            .foregroundStyle(style.colors.text)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: style.metrics.cornerRadius,
                    style: .continuous
                )
            )
    }
}
extension View {
    func primaryButton() -> some View { modifier(PrimaryButton()) }
}

struct FieldBackground: ViewModifier {
    @Environment(\.authUIStyle) private var style
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(style.colors.background.opacity(0.06))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: style.metrics.cornerRadius,
                    style: .continuous
                )
            )
    }
}
extension View {
    func fieldBackground() -> some View { modifier(FieldBackground()) }
}

struct TitleText: ViewModifier {
    @Environment(\.authUIStyle) private var style
    func body(content: Content) -> some View {
        let sys = Font.system(size: style.typography.titleSize, weight: .bold)
        let font =
            style.typography.fontFamily.map {
                Font.custom(
                    $0,
                    size: style.typography.titleSize,
                    relativeTo: .title
                )
            } ?? sys
        return content.font(font).foregroundStyle(style.colors.text)
    }
}
extension View { func authTitle() -> some View { modifier(TitleText()) } }
