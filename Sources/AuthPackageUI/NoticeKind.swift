//
//  NoticeKind.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 12/09/2025.
//


import SwiftUI

public enum NoticeKind {
    case success, error, info

    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.octagon.fill"
        case .info:    return "info.circle.fill"
        }
    }
}

public struct Notice: Identifiable, Equatable {
    public let id = UUID()
    public let kind: NoticeKind
    public let message: String
    public let autoDismissAfter: TimeInterval

    public init(kind: NoticeKind, message: String, autoDismissAfter: TimeInterval = 3.0) {
        self.kind = kind
        self.message = message
        self.autoDismissAfter = autoDismissAfter
    }
}

public struct NoticeBanner: View {
    @Environment(\.authUIStyle) private var style
    @Binding var notice: Notice?

    @State private var isVisible = false

    public init(notice: Binding<Notice?>) {
        self._notice = notice
    }

    public var body: some View {
        VStack {
            if isVisible, let notice {
                banner(for: notice)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear { scheduleAutoDismiss(notice) }
                    .accessibilityAddTraits(.isStaticText)
            }
            Spacer().frame(height: 0)
        }
        .onChange(of: notice) { _ in animateVisibility() }
        .onAppear { animateVisibility() }
    }

    private func banner(for notice: Notice) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: notice.kind.iconName)
                .imageScale(.large)
            Text(notice.message)
                .font(.system(size: style.typography.bodySize, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Button {
                withAnimation(.spring(response: 0.35)) {
                    self.isVisible = false
                    self.notice = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote)
                    .padding(8)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: style.metrics.cornerRadius)
                .fill(bannerBackground(for: notice.kind))
        )
        .foregroundStyle(Color.white)
        .shadow(radius: 6, y: 3)
        .padding(.horizontal)
        .padding(.top)
    }

    private func bannerBackground(for kind: NoticeKind) -> Color {
        switch kind {
        case .success:
            return Color.green.opacity(0.9)
        case .error:
            return Color.red.opacity(0.95)
        case .info:
            return style.colors.primary.opacity(0.95)
        }
    }

    private func scheduleAutoDismiss(_ notice: Notice) {
        guard notice.autoDismissAfter > 0 else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(notice.autoDismissAfter * 1_000_000_000))
            withAnimation(.spring(response: 0.35)) {
                if self.notice?.id == notice.id {
                    self.isVisible = false
                    self.notice = nil
                }
            }
        }
    }

    private func animateVisibility() {
        withAnimation(.spring(response: 0.35)) {
            self.isVisible = (self.notice != nil)
        }
    }
}
