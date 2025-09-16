//
//  StyleModifiers.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//
#if os(iOS)

import SwiftUI

// Fonts
private extension Font {
    static func authTitle(using typo: AuthUIStyleSheet.Typography) -> Font {
        if let family = typo.fontFamily, !family.isEmpty {
            return .custom(family, size: typo.titleSize).weight(.semibold)
        }
        return .system(size: typo.titleSize, weight: .semibold)
    }
    static func authBody(using typo: AuthUIStyleSheet.Typography) -> Font {
        if let family = typo.fontFamily, !family.isEmpty {
            return .custom(family, size: typo.bodySize)
        }
        return .system(size: typo.bodySize)
    }
}

// Title style
public extension View {
    func authTitle() -> some View {
        modifier(AuthTitleModifier())
    }
    func fieldBackground() -> some View {
        modifier(FieldBackgroundModifier())
    }
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
}

private struct AuthTitleModifier: ViewModifier {
    @Environment(\.authUIStyle) private var style
    func body(content: Content) -> some View {
        content
            .font(.authTitle(using: style.typography))
            .foregroundStyle(style.colors.text)
            .padding(.bottom, style.metrics.spacing)
    }
}

private struct FieldBackgroundModifier: ViewModifier {
    @Environment(\.authUIStyle) private var style
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: style.metrics.cornerRadius)
                    .fill(style.colors.background.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: style.metrics.cornerRadius)
                    .stroke(style.colors.text.opacity(0.12))
            )
            .font(.authBody(using: style.typography))
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.authUIStyle) private var style
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.authBody(using: style.typography).weight(.semibold))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: style.metrics.cornerRadius)
                    .fill(style.colors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .foregroundStyle(Color.white)
    }
}
#endif
