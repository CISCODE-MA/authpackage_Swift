//
//  SharedViewBits.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//


import SwiftUI

public struct InlineErrorView: View {
    public let message: String
    public init(message: String) { self.message = message }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.footnote)
        .padding(10)
        .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .foregroundStyle(.red)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

@available(iOS 15.0, macOS 12.0, *)
public struct FormCaption: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

public extension View {
    @available(iOS 15.0, macOS 12.0, *)
    func formCaption() -> some View { modifier(FormCaption()) }
}
