//
//  AuthTheme.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

#if canImport(SwiftUI)
    import SwiftUI
    #if canImport(UIKit)
        import UIKit
    #endif
    #if canImport(AppKit)
        import AppKit
    #endif

    public struct AuthTheme {
        public var primary: Color
        public var background: Color
        public var text: Color
        public var danger: Color
        public var cornerRadius: CGFloat
        public var spacing: CGFloat

        public init(
            primary: Color = .accentColor,
            background: Color? = nil,
            text: Color = .primary,
            danger: Color = .red,
            cornerRadius: CGFloat = 14,
            spacing: CGFloat = 12
        ) {
            self.primary = primary
            self.background = background ?? AuthTheme.systemBackground
            self.text = text
            self.danger = danger
            self.cornerRadius = cornerRadius
            self.spacing = spacing
        }

        static var systemBackground: Color {
            #if canImport(UIKit)
                Color(UIColor.systemBackground)
            #elseif canImport(AppKit)
                Color(NSColor.windowBackgroundColor)
            #else
                Color.white
            #endif
        }
    }
#endif
