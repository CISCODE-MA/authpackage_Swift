# AuthPackage (iOS / Swift) — Core + Drop-in UI

> **Production-ready authentication** for Swift apps, with a strongly-typed core client and a drop-in SwiftUI flow.  
> Includes email/password auth, password reset, and OAuth (Microsoft, Google, Facebook).  
> This README is the **step-by-step integration guide**. It covers architecture, installation, configuration, OAuth setup, CI/CD, troubleshooting, and security.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-15.0+-lightgrey.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)

---

## 📑 Table of Contents

1. [Architecture](#architecture)  
2. [Requirements](#requirements)  
3. [Installation (SPM)](#installation-spm)  
4. [Quick Start](#quick-start)  
5. [Configuration Reference](#configuration-reference)  
6. [App URL Scheme (Info.plist)](#app-url-scheme-infoplist)  
7. [OAuth Providers (Microsoft, Google, Facebook)](#oauth-providers-microsoft-google-facebook)  
8. [Backend Contract](#backend-contract)  
9. [Using the Core API Directly](#using-the-core-api-directly)  
10. [Token Storage & Refresh](#token-storage--refresh)  
11. [Post-Login Deeplink](#post-login-deeplink)  
12. [Troubleshooting](#troubleshooting)  
13. [Security Checklist](#security-checklist)  
14. [CI/CD (Azure Pipelines)](#cicd-azure-pipelines)  
15. [Versioning & Releases](#versioning--releases)  
16. [Contributing](#contributing)  
17. [License](#license)  

---

## 🏗 Architecture

```
       ┌───────────────────────────────────────────────┐
       │                   Your App                    │
       │   SwiftUI navigation, state, feature screens  │
       └──────────────────────▲────────────────────────┘
                              │ consumes
       ┌──────────────────────┴────────────────────────┐
       │                AuthPackageUI                  │
       │  Prebuilt flows (Login, Register, Forgot/Reset│
       │  Theming via CSS-like vars, routing helpers   │
       └──────────────────────▲────────────────────────┘
                              │ uses
       ┌──────────────────────┴────────────────────────┐
       │                 AuthPackage                   │
       │  AuthClient facade, services, endpoints       │
       │  NetworkClient (URLSession)                   │
       └──────────────────────▲────────────────────────┘
                              │ HTTP (JSON/JWT)
       ┌──────────────────────┴────────────────────────┐
       │                    Backend                    │
       │  Express API + Passport (local + OAuth)       │
       │  Issues app JWTs, stores refresh, deep-links  │
       └───────────────────────────────────────────────┘
```

- **Core (`AuthPackage`)** → typed API for login, refresh, logout, register, reset, OAuth.  
- **UI (`AuthPackageUI`)** → SwiftUI screens using the core client; drop-in “auth flow.”  
- **Extensibility** → use Core without UI, or override visuals via theme tokens.

---

## 📋 Requirements

- Xcode 16+  
- iOS 15.0+  
- Swift 5.9+  
- A reachable backend implementing the contract below  

---

## ⚡ Installation (SPM)

1. Xcode → **File** → **Add Package Dependencies…**  
2. Paste repo URL:  
   ```
   https://github.com/Zaiidmo/AuthPackage-Swift.git
   ```
3. Rule: **Up to Next Major** from `1.0.0`.  
4. Add products: **AuthPackage**, **AuthPackageUI**.  

---

## 🚀 Quick Start

```swift
import SwiftUI
import AuthPackage
import AuthPackageUI

@main
struct MyApp: App {
  private let baseURL = URL(string: "http://localhost:3000")! // LAN IP/tunnel for device

  private var ui: AuthUIConfig {
    AuthUIConfig(
      baseURL: baseURL,
      appScheme: "authdemo",
      microsoftEnabled: true,
      googleEnabled: true,
      facebookEnabled: true,
      postLoginDeeplink: URL(string: "authdemo://home")
    )
  }

  private var core: AuthConfiguration {
    AuthConfiguration(
      baseURL: baseURL,
      refreshUsesCookie: true,
      redirectScheme: "authdemo",
      microsoftEnabled: true,
      googleEnabled: true,
      facebookEnabled: true
    )
  }

  var body: some Scene {
    WindowGroup {
      let client = AuthClient(config: core)
      AuthPackageUI.makeRoot(config: ui, client: client)
    }
  }
}
```

> **Tip:** Devices can’t reach `localhost`. Use your LAN IP or HTTPS tunnel (ngrok, Cloudflare) and configure the backend + provider apps with the same host.

---

## ⚙️ Configuration Reference

### `AuthUIConfig` (UI module)
- `baseURL: URL` — backend origin  
- `appScheme: String` — app’s URL scheme (must be in Info.plist)  
- `microsoftEnabled / googleEnabled / facebookEnabled: Bool` — toggle OAuth buttons  
- `postLoginDeeplink: URL?` — open after login (optional)  
- `cssVariables: String?` — theming (CSS-like tokens)  

### `AuthConfiguration` (Core module)
- `baseURL: URL`  
- `refreshUsesCookie: Bool` — enable cookie-based refresh  
- `redirectScheme: String?` — required for OAuth providers  
- `microsoftEnabled / googleEnabled / facebookEnabled: Bool` — enable providers  

---

## 🔑 App URL Scheme (Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>authdemo</string>
    </array>
  </dict>
</array>
```

---

## 🌐 OAuth Providers (Microsoft, Google, Facebook)

All follow the same flow:

1. App opens backend route with `redirect=authdemo://auth/callback`.  
2. Provider login → backend callback → backend mints tokens.  
3. Backend 302 → `authdemo://auth/callback?...` with tokens.  
4. Package saves tokens; user authenticated.  

- **Microsoft** → Azure AD App with callback URLs for localhost, LAN IP, tunnel. Add optional claims (`email`, `upn`, `preferred_username`).  
- **Google** → GCP OAuth client with redirect URIs; scopes: `email`, `profile`.  
- **Facebook** → App in Meta Developer; valid redirect URIs; permissions: `email`.  

---

## 📡 Backend Contract

- `POST /api/auth/clients/login` → `{ accessToken, refreshToken }`  
- `POST /api/auth/refresh-token` → `{ accessToken }`  
- `POST /api/auth/logout`  
- `POST /api/auth/forgot-password`  
- `POST /api/auth/reset-password`  
- `POST /api/clients/register`  
- `GET /api/auth/{provider}?redirect=<scheme>://auth/callback`  
- `GET /api/auth/{provider}/callback` → 302 with tokens  
- `POST /api/auth/{provider}/exchange` (native SDK → app tokens)  

---

## 🛠 Using the Core API Directly

```swift
let client = AuthClient(config: core)

// Email/password
let claims = try await client.login(email: "user@example.com", password: "Secret123!")

// OAuth
let window = UIApplication.shared.connectedScenes
  .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first!
let googleClaims = try await client.loginWithGoogle(from: window)

// Refresh
let access = try await client.refreshIfNeeded()

// Logout
try await client.logout()
```

---

## 🔄 Token Storage & Refresh

- Default → in-memory  
- Production → provide a `TokenStore` backed by **Keychain**  
- `refreshIfNeeded()` uses refresh token or HttpOnly cookie  

---

## 🔗 Post-Login Deeplink

If `postLoginDeeplink` is set, the UI opens it after success. Handle in your app (`authdemo://home`) to route.  

---

## 🩺 Troubleshooting

- **AADSTS500113** → missing redirect in Azure → add exact URL  
- **OAuth sheet loops** → hostname mismatch or missing claims  
- **No deep-link** → Info.plist scheme mismatch  
- **Device fails, simulator works** → device can’t reach `localhost` → use LAN IP/tunnel  
- **OAuth user missing email** → add scopes/permissions in provider  

---

## 🔐 Security Checklist

- Use HTTPS in production  
- Store tokens in Keychain  
- Rotate refresh tokens  
- Don’t log tokens  
- Use unique app schemes  
- Lock down backend CORS + callbacks  

---

## ⚙️ CI/CD (Azure Pipelines)

- Run SwiftPM tests on macOS  
- Export LCOV coverage  
- Publish zipped source artifact  
- Optionally: publish to Azure Artifacts or run Sonar analysis  

---

## 📦 Versioning & Releases

- **Semantic Versioning (SemVer)**  
- Stable releases tagged `vX.Y.Z`  
- Pre-releases via `release` branch → `NEXT_MINOR.0-rc.YYYYMMDD.BUILDID`  
- See [CHANGELOG.md](CHANGELOG.md) for details  

---

## 🤝 Contributing

- Open issues for bugs/feature requests  
- Fork & PR  
- Run `swift test` before pushing  
- Follow forthcoming `CONTRIBUTING.md`  

---

## 📜 License

Licensed under the [MIT License](LICENSE.md).  
© 2025 AuthPackage contributors

---

## Contributing

We welcome contributions! Please read the [Contributing Guide](CONTRIBUTING.md) before opening an issue or pull request.
It explains our branching model, coding standards, commit message conventions, and how to run tests locally.

- **Pull Requests:** For all changes, open a PR targeting the default branch and ensure CI checks pass.
- **Conventional Commits:** Please use the [Conventional Commits](https://www.conventionalcommits.org/) format (e.g. `feat:`, `fix:`, `docs:`). This powers automated changelog generation.
- **Code of Conduct:** Be respectful and constructive. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) (if present).

## Changelog

We maintain a human-friendly changelog in [CHANGELOG.md](CHANGELOG.md) following the
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format and [Semantic Versioning](https://semver.org/).

- **Latest release:** See the [releases](https://github.com/your-org/your-repo/releases) page.
- **Unreleased changes:** Tracked under the **[Unreleased]** section until a version is tagged.

## Releases & Versioning

This project follows **Semantic Versioning** (`MAJOR.MINOR.PATCH`). Release automation is driven by CI:
- **Release tags:** Create an annotated tag `vX.Y.Z` on the default branch to publish a stable release.
- **RC builds:** Commits on the `release` branch produce RC versions like `X.(MINOR+1).0-rc.YYYYMMDD.BUILDID`.
- **Artifacts:** CI attaches source archives and publishes coverage; see pipeline details in `/azure-pipelines.yml`.

### First Official Release (resetting history of tags)

If you want to make this repository's **first official open-source release** and **discard all previous tags**:
> ⚠️ Note: This rewrites *tag history only*; it does **not** rewrite commit history.

1. **Delete old tags locally:**
   ```bash
   git tag -l | xargs -n 1 git tag -d
   ```
2. **Delete old tags on origin (GitHub):**
   ```bash
   # Delete all remote tags in bulk
   git ls-remote --tags origin | awk '{print $2}' | sed "s#refs/tags/##" | xargs -n 1 -I {} git push origin :refs/tags/{}
   ```
3. **Create the first official tag and push it:**
   ```bash
   export VERSION=1.0.0
   git tag -a "v${VERSION}" -m "AuthPackage v${VERSION} — first public release"
   git push origin "refs/tags/v${VERSION}"
   ```
4. **Update the changelog:** Move items from **[Unreleased]** into **[v${VERSION} - 2025-09-24]** in `CHANGELOG.md`.

> Tip: If your default branch is protected, grant your CI GitHub App permission to push the tag or create the tag via a PR merged commit.

## Security

If you discover a security issue, please **do not** open a public issue. Email the maintainers or follow the security policy if available in `SECURITY.md`.

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.
