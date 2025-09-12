//
//  PostLoginView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import SwiftUI

public struct PostLoginView: View {
    let onLogout: () -> Void
    @Environment(\.authUIStyle) private var style

    public init(onLogout: @escaping () -> Void) { self.onLogout = onLogout }

    public var body: some View {
        VStack(spacing: style.metrics.spacing) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 48))
            Text("You're signed in").font(.system(size: style.typography.titleSize, weight: .semibold))
            Button("Log out", action: onLogout).buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
