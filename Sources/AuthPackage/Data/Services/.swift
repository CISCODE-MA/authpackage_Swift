//
//  ProfileViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 06/10/2025.
//


import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(UserProfile)
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published var draft: UpdateProfileInput? // used in Edit screen
    @Published var isSaving: Bool = false

    private let service: ProfileService

    init(service: ProfileService) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let profile = try await service.fetchProfile()
            state = .loaded(profile)
        } catch {
            state = .error((error as? LocalizedError)?.errorDescription ?? "Failed to load profile.")
        }
    }

    func beginEditing() {
        guard case .loaded(let profile) = state else { return }
        draft = UpdateProfileInput(
            avatarURL: profile.avatarURL,
            username: profile.username,
            email: profile.email,
            phoneNumber: profile.phoneNumber
        )
    }

    func validateDraft() -> String? {
        guard let d = draft else { return "Nothing to save." }
        if d.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Username cannot be empty."
        }
        if !Self.isValidEmail(d.email) {
            return "Email format is invalid."
        }
        if let phone = d.phoneNumber, !phone.isEmpty, !Self.isValidPhone(phone) {
            return "Phone number is invalid."
        }
        return nil
    }

    func hasChanges() -> Bool {
        guard let d = draft, case .loaded(let p) = state else { return false }
        return d.avatarURL != p.avatarURL ||
               d.username != p.username ||
               d.email != p.email ||
               (d.phoneNumber ?? "") != (p.phoneNumber ?? "")
    }

    func save() async {
        guard validateDraft() == nil, let d = draft else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await service.updateProfile(d)
            state = .loaded(updated)
            draft = nil
        } catch {
            state = .error((error as? LocalizedError)?.errorDescription ?? "Failed to update profile.")
        }
    }

    // MARK: - Helpers
    static func displayName(from profile: UserProfile) -> String {
        let base = profile.username.isEmpty ? profile.email.split(separator: "@").first.map(String.init) ?? "User" : profile.username
        return base
    }

    static func initials(from nameOrEmail: String) -> String {
        let trimmed = nameOrEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "?" }
        let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        // fallback to email first letter or first two letters
        return String(trimmed.prefix(2)).uppercased()
    }

    static func isValidEmail(_ value: String) -> Bool {
        // Simple and testable; good enough here.
        let pattern = #"^\S+@\S+\.\S+$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidPhone(_ value: String) -> Bool {
        let digits = value.filter(\.isNumber)
        return (7...15).contains(digits.count)
    }
}
