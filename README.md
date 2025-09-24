# AuthPackage (iOS / Swift) — Core + Drop-in UI

> **Production-ready authentication** for Swift apps, with a strongly-typed core client and a drop-in SwiftUI flow.  
> Includes email/password auth, password reset, and OAuth (Microsoft, Google, Facebook).  
> This README is the **step-by-step integration guide**. It covers architecture, install, configuration, OAuth setup, CI/CD, troubleshooting, and security.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-15.0+-lightgrey.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📑 Table of Contents

1. [Architecture](#architecture)  
2. [Requirements](#requirements)  
3. [Install & Run (60s)](#-install--run-60s)  
4. [Configuration Reference](#️-configuration-reference)  
5. [App URL Scheme (Info.plist)](#-app-url-scheme-infoplist)  
6. [OAuth Providers (Microsoft, Google, Facebook)](#-oauth-providers-microsoft-google-facebook)  
7. [Backend Contract](#-backend-contract)  
8. [Using the Core API Directly](#-using-the-core-api-directly)  
9. [Token Storage & Refresh](#-token-storage--refresh)  
10. [Post-Login Deeplink](#-post-login-deeplink)  
11. [Troubleshooting](#-troubleshooting)  
12. [Security Checklist](#-security-checklist)  
13. [CI/CD (Azure Pipelines)](#-cicd-azure-pipelines)  
14. [Versioning & Releases](#-versioning--releases)  
15. [Changelog](#changelog)  
16. [Contributing](#-contributing)  
17. [License](#-license)  

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

## ⚡ Install & Run (60s)

### 1) Add package (SPM)

Xcode → **File** → **Add Package Dependencies…** →  
URL: `https://github.com/Zaiidmo/AuthPackage-swift.git` → Products: **AuthPackage**, **AuthPackageUI** → Version: **Up to Next Major** from `1.0.0`.

### 2) Register your URL scheme (Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>authdemo</string> <!-- change to your scheme -->
    </array>
  </dict>
</array>
```

### 3) Show the drop-in UI (persistent client + post-login deeplink)

```swift
import SwiftUI
import AuthPackage
import AuthPackageUI

enum AuthSecrets {
  static let baseURL = URL(string: "https://YOUR-BACKEND.example.com")!
  static let scheme  = "authdemo"              // must match Info.plist
  static let keychainService = "com.example.AuthDemo"
  static let keychainAccount = "auth"
}

enum AuthDependencies {
  static let client: AuthClientProtocol = {
    let cfg = AuthConfiguration(
      baseURL: AuthSecrets.baseURL,
      refreshUsesCookie: true,
      redirectScheme: AuthSecrets.scheme,
      microsoftEnabled: true,
      googleEnabled: true,
      facebookEnabled: true
    )
    let store = KeychainTokenStore(
      service: AuthSecrets.keychainService,
      account: AuthSecrets.keychainAccount
    )
    return AuthClient(config: cfg, tokenStore: store)
  }()
}

@main
struct MyApp: App {
  private let client = AuthDependencies.client
  @State private var showHome = false

  var body: some Scene {
    WindowGroup {
      Group {
        if showHome {
          Text("Home") // replace with your HomeView
        } else {
          AuthPackageUI.makeRoot(
            config: AuthUIConfig(
              baseURL: AuthSecrets.baseURL,
              appScheme: AuthSecrets.scheme,
              microsoftEnabled: true,
              googleEnabled: true,
              facebookEnabled: true,
              cssVariables: """
              :root {
                --authui-primary-color: #B53CC2;
                --authui-accent-color:  #D078FF;
                --authui-background-color: #1F1F1F;
                --authui-text-color:     #ffffff;
                --authui-corner-radius: 8;
                --authui-spacing:       14;
                --authui-font-family:   Poppins;
                --authui-title-size:    28;
                --authui-body-size:     17;
              }
              """,
              postLoginDeeplink: URL(string: "\(AuthSecrets.scheme)://home")
            ),
            client: client
          )
        }
      }
      .onAppear {
        if let t = client.tokens?.accessToken, !t.isEmpty { showHome = true }
      }
      .onOpenURL { url in
        guard url.scheme == AuthSecrets.scheme else { return }
        if url.host == "home" { showHome = true }
      }
    }
  }
}
```

> **Device tip:** real devices can’t reach `localhost`. Use your LAN IP or an HTTPS tunnel (ngrok, Cloudflare), and ensure your backend + provider apps use the same host in their redirect URLs.

---

## ⚙️ Configuration Reference

### `AuthUIConfig` (UI module)
| Property | Type | Notes |
|---|---|---|
| `baseURL` | `URL` | Backend origin |
| `appScheme` | `String` | Must match Info.plist scheme |
| `microsoftEnabled` / `googleEnabled` / `facebookEnabled` | `Bool` | Toggle OAuth buttons |
| `postLoginDeeplink` | `URL?` | Open after login (optional) |
| `cssVariables` | `String?` | CSS-like theme tokens |

### `AuthConfiguration` (Core module)
| Property | Type | Notes |
|---|---|---|
| `baseURL` | `URL` | Backend origin |
| `refreshUsesCookie` | `Bool` | Enable cookie-based refresh |
| `redirectScheme` | `String?` | Required for OAuth flows |
| `microsoftEnabled` / `googleEnabled` / `facebookEnabled` | `Bool` | Enable providers |

---

## 🔑 App URL Scheme (Info.plist)

> Already shown in **Install & Run**. Ensure your scheme matches `appScheme` and provider redirect URIs.

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

> Keep endpoint names consistent across login/register (either use `/api/auth/**` or `/api/clients/**` for both).

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

### First Official Release (resetting history of tags)

If you want to make this repository's **first official open-source release** and **discard all previous tags**:  
> ⚠️ This rewrites *tag history only*; it does **not** rewrite commit history.

1. **Delete old tags locally:**
   ```bash
   git tag -l | xargs -n 1 git tag -d
   ```
2. **Delete old tags on origin (GitHub):**
   ```bash
   git ls-remote --tags origin | awk '{print $2}' | sed "s#refs/tags/##" | xargs -n 1 -I {} git push origin :refs/tags/{}
   ```
3. **Create the first official tag and push it:**
   ```bash
   export VERSION=1.0.0
   git tag -a "v${VERSION}" -m "AuthPackage v${VERSION} — first public release"
   git push origin "refs/tags/v${VERSION}"
   ```
4. **Update the changelog:** Move items from **[Unreleased]** into **[v${VERSION} - YYYY-MM-DD]** in `CHANGELOG.md`.

> If your default branch is protected, grant your CI GitHub App permission to push the tag or create the tag via a PR merged commit.

---

## Changelog

We maintain a human-friendly changelog in [CHANGELOG.md](CHANGELOG.md) following the
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format and [Semantic Versioning](https://semver.org/).

- **Latest release:** See the repo **Releases** page.
- **Unreleased changes:** Tracked under the **[Unreleased]** section until a version is tagged.

---

## 🤝 Contributing

Please read the [Contributing Guide](CONTRIBUTING.md) before opening an issue or pull request. It explains our branching model, coding standards, commit message conventions, and how to run tests locally.

- **Pull Requests:** Open a PR targeting the default branch and ensure CI checks pass.
- **Conventional Commits:** Use the [Conventional Commits](https://www.conventionalcommits.org/) format (e.g. `feat:`, `fix:`, `docs:`). This powers automated changelog generation.
- **Code of Conduct:** Be respectful and constructive. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

## 📜 License

Licensed under the [MIT License](LICENSE).  
© 2025 AuthPackage contributors
