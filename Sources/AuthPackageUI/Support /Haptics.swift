//
//  Haptics.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 09/09/2025.
//

#if os(iOS)
    import UIKit

    enum Haptics {
        @MainActor static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        @MainActor static func error() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
#else
    enum Haptics {
        static func success() {}
        static func error() {}
    }
#endif
