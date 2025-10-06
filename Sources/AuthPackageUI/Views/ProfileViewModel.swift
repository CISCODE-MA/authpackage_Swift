//
//  ProfileViewModel.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 06/10/2025.
//


import Foundation
import AuthPackage

public enum ProfileVMState: Equatable {
  case idle
  case loading
  case loaded(UserProfile)
  case editing(UserProfile, draft: Draft)
  case error(String)

  public struct Draft: Equatable, Sendable {
    public var avatarURLString: String
    public var username: String
    public var email: String
    public var phone: String
  }
}

public final class ProfileViewModel: ObservableObject {
  private let store: any ProfileStore

  @Published public private(set) var state: ProfileVMState = .idle
  @Published public private(set) var isSaving = false

  public init(store: ProfileStore) { self.store = store }

  @MainActor public func load() async {
    state = .loading
    do {
      let p = try await store.load()
      state = .loaded(p)
    } catch {
      state = .error(String(describing: error))
    }
  }

  @MainActor public func beginEdit() {
    guard case .loaded(let p) = state else { return }
    state = .editing(p, draft: .init(
      avatarURLString: p.avatarURL?.absoluteString ?? "",
      username: p.username,
      email: p.email,
      phone: p.phoneNumber ?? ""
    ))
  }

  @MainActor public func cancelEdit() {
    if case .editing(let p, _) = state { state = .loaded(p) }
  }

  // Draft updates
  @MainActor public func setAvatarURL(_ s: String) {
    if case .editing(let p, var d) = state { d.avatarURLString = s; state = .editing(p, draft: d) }
  }
  @MainActor public func setUsername(_ s: String) {
    if case .editing(let p, var d) = state { d.username = s; state = .editing(p, draft: d) }
  }
  @MainActor public func setEmail(_ s: String) {
    if case .editing(let p, var d) = state { d.email = s; state = .editing(p, draft: d) }
  }
  @MainActor public func setPhone(_ s: String) {
    if case .editing(let p, var d) = state { d.phone = s; state = .editing(p, draft: d) }
  }

  // Validations
  public func validationError(for draft: ProfileVMState.Draft) -> String? {
    if let m = ProfileRules.validateUsername(draft.username) { return m }
    if let m = ProfileRules.validateEmail(draft.email) { return m }
    return nil
  }

  @MainActor public func save() async {
    guard case .editing(let original, let d) = state else { return }

    if let m = validationError(for: d) {
      state = .error(m); return
    }

    var next = original
    next.username = d.username
    next.email = d.email
    next.phoneNumber = d.phone.isEmpty ? nil : d.phone
    if let url = URL(string: d.avatarURLString), !d.avatarURLString.isEmpty {
      next.avatarURL = url
    } else {
      next.avatarURL = nil
    }

    isSaving = true
    do {
      let updated = try await store.save(next)
      state = .loaded(updated)
    } catch {
      state = .error("Save failed. Please try again.")
    }
    isSaving = false
  }
}
