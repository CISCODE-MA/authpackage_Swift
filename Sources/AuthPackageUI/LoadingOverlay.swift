//
//  LoadingOverlay.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

#if os(iOS)
    import SwiftUI

    public struct LoadingOverlay: View {
        public let isVisible: Bool
        public init(isVisible: Bool) { self.isVisible = isVisible }

        public var body: some View {
            if isVisible {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Please wait…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 24)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .shadow(radius: 10)
                }
                .transition(.opacity)
      
            }
        }
    }
#endif
