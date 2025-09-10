//
//  PasswordStrengthView.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//


import SwiftUI

public struct PasswordStrengthView: View {
    public enum Strength: String { case veryWeak, weak, fair, good, strong }
    let strength: Strength

    public init(for password: String) {
        self.strength = PasswordStrengthView.estimate(password)
    }

    public var body: some View {
        HStack(spacing: 8) {
            ProgressView(value: progress).frame(maxWidth: .infinity)
            Text(label).font(.footnote).foregroundStyle(color)
        }
        .padding(.top, 4)
    }

    private var progress: Double {
        switch strength {
        case .veryWeak: 0.1
        case .weak:     0.25
        case .fair:     0.5
        case .good:     0.75
        case .strong:   1.0
        }
    }
    private var label: String { strength.rawValue.capitalized }
    private var color: Color {
        switch strength {
        case .veryWeak, .weak: .red
        case .fair: .orange
        case .good: .yellow
        case .strong: .green
        }
    }

    private static func estimate(_ s: String) -> Strength {
        let lengthScore = min(Double(s.count) / 12.0, 1.0)
        let variety = [
            CharacterSet.lowercaseLetters,
            CharacterSet.uppercaseLetters,
            CharacterSet.decimalDigits,
            CharacterSet.punctuationCharacters
        ].map { s.rangeOfCharacter(from: $0) != nil ? 1.0 : 0.0 }.reduce(0, +)
        let score = 0.6 * lengthScore + 0.4 * (variety / 4.0)
        switch score {
        case ..<0.2: return .veryWeak
        case ..<0.4: return .weak
        case ..<0.6: return .fair
        case ..<0.8: return .good
        default:     return .strong
        }
    }
}
