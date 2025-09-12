//
//  AuthUIStyleSheet.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

public struct AuthUIStyleSheet: Sendable {
    public struct Colors: Sendable {
        public var background: Color
        public var primary: Color
        public var text: Color
        public var accent: Color
        public init(
            background: Color,
            primary: Color,
            text: Color,
            accent: Color
        ) {
            self.background = background
            self.primary = primary
            self.text = text
            self.accent = accent
        }
    }

    public struct Metrics: Sendable {
        public var cornerRadius: CGFloat
        public var spacing: CGFloat
        public init(cornerRadius: CGFloat, spacing: CGFloat) {
            self.cornerRadius = cornerRadius
            self.spacing = spacing
        }
    }

    public struct Typography: Sendable {
        public var fontFamily: String?
        public var titleSize: CGFloat
        public var bodySize: CGFloat
        public init(
            fontFamily: String? = nil,
            titleSize: CGFloat = 28,
            bodySize: CGFloat = 17
        ) {
            self.fontFamily = fontFamily
            self.titleSize = titleSize
            self.bodySize = bodySize
        }
    }

    public var colors: Colors
    public var metrics: Metrics
    public var typography: Typography

    public init(colors: Colors, metrics: Metrics, typography: Typography) {
        self.colors = colors
        self.metrics = metrics
        self.typography = typography
    }

    public static let `default` = AuthUIStyleSheet(
        colors: .init(
            background: Color(uiColor: .systemBackground),
            primary: .accentColor,
            text: .primary,
            accent: .blue
        ),
        metrics: .init(cornerRadius: 12, spacing: 12),
        typography: .init()
    )
}

// MARK: - CSS variables → style
extension AuthUIStyleSheet {
    public static func fromCSSVariables(_ css: String) -> Self {
        let dict = parseCSSVariables(css)
        func color(_ key: String, fallback: Color) -> Color {
            Color.fromHex(dict[key]) ?? fallback
        }
        func num(_ key: String, fallback: CGFloat) -> CGFloat {
            if let raw = dict[key]?.trimmingCharacters(in: .whitespaces),
                let d = Double(raw)
            {
                return CGFloat(d)
            }
            return fallback
        }

        let colors = Colors(
            background: color(
                "--authui-background-color",
                fallback: Color(uiColor: .systemBackground)
            ),
            primary: color("--authui-primary-color", fallback: .accentColor),
            text: color("--authui-text-color", fallback: .primary),
            accent: color("--authui-accent-color", fallback: .blue)
        )
        let metrics = Metrics(
            cornerRadius: num("--authui-corner-radius", fallback: 12),
            spacing: num("--authui-spacing", fallback: 12)
        )
        let typo = Typography(
            fontFamily: dict["--authui-font-family"].flatMap {
                $0.isEmpty ? nil : $0
            },
            titleSize: num("--authui-title-size", fallback: 28),
            bodySize: num("--authui-body-size", fallback: 17)
        )
        return .init(colors: colors, metrics: metrics, typography: typo)
    }

    private static func parseCSSVariables(_ css: String) -> [String: String] {
        var out: [String: String] = [:]
        css.replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: ";")
            .forEach { pair in
                guard let colon = pair.firstIndex(of: ":") else { return }
                let key = String(pair[..<colon]).trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                let value = String(pair[pair.index(after: colon)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if key.hasPrefix("--") { out[key] = value }
            }
        return out
    }
}

extension Color {
    /// Create a Color from hex like #RRGGBB or #RRGGBBAA
    fileprivate static func fromHex(_ maybeHex: String?) -> Color? {
        guard var s = maybeHex?.trimmingCharacters(in: .whitespacesAndNewlines),
            !s.isEmpty
        else { return nil }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8, let v = UInt64(s, radix: 16) else {
            return nil
        }
        let r: Double
        let g: Double
        let b: Double
        let a: Double
        if s.count == 6 {
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255
            a = 1
        } else {
            r = Double((v >> 24) & 0xFF) / 255
            g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >> 8) & 0xFF) / 255
            a = Double(v & 0xFF) / 255
        }
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
