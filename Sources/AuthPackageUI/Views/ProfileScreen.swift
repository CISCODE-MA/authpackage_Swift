//
//  ProfileScreen.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 06/10/2025.
//
#if os(iOS)

    import SwiftUI
    import AuthPackage  // exposes UserProfile + ProfileStore

    public struct ProfileScreen: View {
        @StateObject private var vm: ProfileViewModel

        public init(store: ProfileStore) {
            _vm = StateObject(wrappedValue: ProfileViewModel(store: store))
        }

        public var body: some View {
            Group {
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        content.navigationTitle("Profile").toolbar { toolbar }
                    }
                } else {
                    NavigationView {
                        content.navigationTitle("Profile").toolbar { toolbar }
                    }
                }
            }
            .task { await vm.load() }
        }

        @ViewBuilder private var content: some View {
            switch vm.state {
            case .idle, .loading:
                ProgressView("Loading…").frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            case .error(let msg):
                VStack(spacing: 8) {
                    Text("Couldn’t load profile").font(.headline)
                    Text(msg).foregroundColor(.secondary)
                    Button("Retry") { Task { await vm.load() } }
                }.padding()

            case .loaded(let p):
                ScrollView {
                    VStack(spacing: 16) {
                        avatarView(p)
                        summaryView(p)
                    }.container()
                }

            case .editing(let p, let draft):
                ScrollView {
                    VStack(spacing: 16) {
                        avatarEditView(draft)
                        editor(draft)
                    }.container()
                }
            }
        }

        // MARK: - Pieces

        private func avatarView(_ p: UserProfile) -> some View {
            avatarCircle(username: p.username, url: p.avatarURL)
                .padding(.top, 24)
        }

        private func avatarEditView(_ d: ProfileVMState.Draft) -> some View {
            VStack(spacing: 8) {
                avatarCircle(
                    username: d.username,
                    url: URL(string: d.avatarURLString)
                )
                TextField(
                    "Avatar URL (https://…)",
                    text: Binding(
                        get: { d.avatarURLString },
                        set: { vm.setAvatarURL($0) }
                    )
                )
                .textContentType(.URL)
                .modifier(NoAutoCapsCompat())
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(
                        .secondary.opacity(0.12)
                    )
                )
            }
            .padding(.top, 24)
        }

        private func avatarCircle(username: String, url: URL?) -> some View {
            let initials = username.split(separator: " ").compactMap(\.first)
                .prefix(2).map(String.init).joined().uppercased()
            return Group {
                if let url {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        ZStack {
                            Circle().fill(.gray.opacity(0.2))
                            ProgressView()
                        }
                    }
                } else {
                    ZStack {
                        Circle().fill(.gray.opacity(0.2))
                        Text(initials).font(.headline)
                    }
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))
        }

        private func summaryView(_ p: UserProfile) -> some View {
            VStack(spacing: 12) {
                info("USERNAME", p.username)
                info("EMAIL", p.email)
                info("PHONE", p.phoneNumber ?? "—")
            }
        }

        private func editor(_ d: ProfileVMState.Draft) -> some View {
            VStack(spacing: 12) {
                TextField(
                    "Username",
                    text: Binding(
                        get: { d.username },
                        set: { vm.setUsername($0) }
                    )
                )
                .textContentType(.username)
                .modifier(NoAutoCapsCompat())
                .fieldBG()

                TextField(
                    "Email",
                    text: Binding(get: { d.email }, set: { vm.setEmail($0) })
                )
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .modifier(NoAutoCapsCompat())
                .fieldBG()

                TextField(
                    "Phone",
                    text: Binding(get: { d.phone }, set: { vm.setPhone($0) })
                )
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .fieldBG()

                if let err = vm.validationError(for: d) {
                    Text(err).foregroundColor(.red).frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }
            }
        }

        private func info(_ title: String, _ value: String) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.body)
            }.fieldBG()
        }

        // MARK: - Toolbar

        private var toolbar: some ToolbarContent {
            ToolbarItemGroup(placement: .topBarTrailing) {
                switch vm.state {
                case .loaded:
                    Button("Edit") { vm.beginEdit() }
                case .editing(_, let d):
                    Button("Save") { Task { await vm.save() } }
                        .disabled(
                            vm.validationError(for: d) != nil || vm.isSaving
                        )
                    Button("Cancel") { vm.cancelEdit() }
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Small helpers

    private struct NoAutoCapsCompat: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content.textInputAutocapitalization(.never)
            } else {
                content.autocapitalization(.none)
            }
        }
    }

    extension View {
        fileprivate func container() -> some View {
            self.frame(maxWidth: 600).padding()
        }
        fileprivate func fieldBG() -> some View {
            self
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(
                        .secondary.opacity(0.12)
                    )
                )
        }
    }

#endif  // os(iOS)
