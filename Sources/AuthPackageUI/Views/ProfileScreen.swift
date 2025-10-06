//
//  ProfileScreen.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 06/10/2025.
//
#if os(iOS) // <-- compile this view only for iOS

import SwiftUI
import UIKit
import AuthPackage

#if canImport(PhotosUI)
import PhotosUI
#endif

public struct ProfileScreen: View {
  @State private var isEditing = false
  @State private var profile: UserProfile?
  @State private var errorText: String?
  @State private var loading = true

  // edit state
  @State private var editUsername = ""
  @State private var editEmail    = ""
  @State private var editPhone    = ""

  // avatar selection (iOS 16+ only)
  #if canImport(PhotosUI)
  @State private var pickedImageData: Data?
  @available(iOS 16.0, *)
  @State private var pickerItem: PhotosPickerItem?
  #endif

  let store: ProfileStore

  public init(store: ProfileStore) { self.store = store }

  public var body: some View {
    Group {
      if #available(iOS 16.0, *) {
        NavigationStack { content.navigationTitle("Profile").toolbar { toolbar } }
      } else {
        NavigationView { content.navigationTitle("Profile").toolbar { toolbar } }
      }
    }
    .task { await load() }
    #if canImport(PhotosUI)
    .modifier(PhotoPickReactCompat(pickerItem: $pickerItem, pickedImageData: $pickedImageData))
    #endif
  }

  // MARK: - Content

  @ViewBuilder private var content: some View {
    if loading {
      ProgressView("Loading…").frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if let p = profile {
      ScrollView {
        VStack(spacing: 16) {
          avatarBlock(username: p.username, url: p.avatarURL)
          if isEditing { editor } else { summary(for: p) }
          if let e = errorText { Text(e).foregroundColor(.red).padding(.top, 8) }
        }
        .frame(maxWidth: 600)
        .padding()
      }
    } else {
      VStack(spacing: 8) {
        Text("Couldn’t load profile").font(.headline)
        if let e = errorText { Text(e).foregroundColor(.secondary) }
        Button("Retry") { Task { await load() } }
      }.padding()
    }
  }

  // MARK: - Pieces

  @ViewBuilder private func avatarBlock(username: String, url: URL?) -> some View {
    let initials = username.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined().uppercased()
    VStack {
      Group {
        #if canImport(PhotosUI)
        if let data = pickedImageData, let ui = UIImage(data: data) {
          Image(uiImage: ui).resizable().scaledToFill()
        } else {}
        #endif
        if let url {
          AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: {
            ZStack { Circle().fill(.gray.opacity(0.2)); ProgressView() }
          }
        } else {
          ZStack { Circle().fill(.gray.opacity(0.2)); Text(initials).font(.headline) }
        }
      }
      .frame(width: 96, height: 96)
      .clipShape(Circle())
      .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))

      if isEditing {
        #if canImport(PhotosUI)
        if #available(iOS 16.0, *) {
          PhotosPicker(selection: $pickerItem, matching: .images) {
            Label("Change photo", systemImage: "camera")
          }
        } else {
          Label("Change photo (iOS 16+)", systemImage: "camera").foregroundColor(.secondary)
        }
        #endif
      }
    }
    .padding(.top, 24)
  }

  private func summary(for p: UserProfile) -> some View {
    VStack(spacing: 12) {
      info("USERNAME", p.username)
      info("EMAIL", p.email)
      info("PHONE", p.phoneNumber ?? "—")
    }
  }

  private var editor: some View {
    VStack(spacing: 12) {
      TextField("Username", text: $editUsername)
        .textContentType(.username)
        .modifier(NoAutoCapsCompat())
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.12)))

      TextField("Email", text: $editEmail)
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .modifier(NoAutoCapsCompat())
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.12)))

      TextField("Phone", text: $editPhone)
        .keyboardType(.phonePad)
        .textContentType(.telephoneNumber)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.12)))
    }
  }

  private func info(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.caption).foregroundColor(.secondary)
      Text(value).font(.body)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(RoundedRectangle(cornerRadius: 12).fill(.secondary.opacity(0.12)))
  }

  private var toolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      if let _ = profile {
        if isEditing { Button("Save") { Task { await save() } }.disabled(!isValid) }
        Button(isEditing ? "Cancel" : "Edit") { toggleEdit() }
      }
    }
  }

  // MARK: - Actions

  private func load() async {
    loading = true; errorText = nil
    do {
      let p = try await store.load()
      profile = p
      seedEditors(from: p)
    } catch { profile = nil; errorText = String(describing: error) }
    loading = false
  }

  private func toggleEdit() {
    if isEditing, let p = profile { seedEditors(from: p) } // cancel → reset
    withAnimation { isEditing.toggle() }
  }

  private func seedEditors(from p: UserProfile) {
    editUsername = p.username
    editEmail = p.email
    editPhone = p.phoneNumber ?? ""
    #if canImport(PhotosUI)
    pickedImageData = nil
    #endif
  }

  private var isValid: Bool {
    validateUsername(editUsername) == nil && validateEmail(editEmail) == nil
  }

  private func validateUsername(_ v: String) -> String? {
    v.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 ? nil : "Username must be at least 2 characters."
  }
  private func validateEmail(_ v: String) -> String? {
    let rx = try! NSRegularExpression(pattern: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#, options: [.caseInsensitive])
    return rx.firstMatch(in: v, range: NSRange(location: 0, length: v.utf16.count)) == nil ? "Enter a valid email." : nil
  }

  private func save() async {
    guard var p = profile else { return }
    p.username = editUsername
    p.email = editEmail
    p.phoneNumber = editPhone.isEmpty ? nil : editPhone

    do {
      #if canImport(PhotosUI)
      let updated = try await store.save(p, avatarJPEG: pickedImageData)
      #else
      let updated = try await store.save(p, avatarJPEG: nil)
      #endif
      profile = updated
      withAnimation { isEditing = false }
      errorText = nil
    } catch { errorText = "Save failed. Please try again." }
  }
}

// MARK: - Compat helpers

/// iOS15: replicate `.textInputAutocapitalization(.never)`
fileprivate struct NoAutoCapsCompat: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 16.0, *) {
      content.textInputAutocapitalization(.never)
    } else {
      content.autocapitalization(.none)
    }
  }
}

#if canImport(PhotosUI)
fileprivate struct PhotoPickReactCompat: ViewModifier {
  @Binding var pickerItem: Any?
  @Binding var pickedImageData: Data?

  init(pickerItem: Binding<PhotosPickerItem?>, pickedImageData: Binding<Data?>) {
    _pickerItem = Binding<Any?>(get: { pickerItem.wrappedValue }, set: { pickerItem.wrappedValue = $0 as? PhotosPickerItem })
    _pickedImageData = pickedImageData
  }

  func body(content: Content) -> some View {
    if #available(iOS 16.0, *) {
      content.task(id: pickerItem as? PhotosPickerItem) {
        guard let item = pickerItem as? PhotosPickerItem else { return }
        do { pickedImageData = try await item.loadTransferable(type: Data.self) } catch { pickedImageData = nil }
      }
    } else {
      content
    }
  }
}
#endif

#endif // os(iOS)
