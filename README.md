# AuthPackage (iOS / Swift) — Core + Drop-in UI

> **Purpose**  
> AuthPackage is a production-ready Swift package that integrates with your Express-based authentication backend.  
> It provides:
> - A clean **core facade** (`AuthPackage`) for login, logout, refresh, registration, password reset, and  Microsoft OAuth.  
> - A ready-made **SwiftUI UI module** (`AuthPackageUI`) shipping pre-built views: Login, Registration, Forgot/Reset, Post-login.  
> - **Theming and configuration** so new apps can install, configure once, and get a complete auth flow.

---

## Table of Contents

1. [Architecture](#architecture)  
2. [Installation (SPM)](#installation-spm)  
3. [Configuration](#configuration)  
4. [Quick Start](#quick-start) 
5. [Backend Contract](#backend-contract)  
6. [Public API](#public-api)  
7. [Theming](#theming)  
8. [Post-Login Redirect](#post-login-redirect)  
9. [Error Handling](#error-handling)  
10. [Token Storage](#token-storage)  
11. [Platform Notes](#platform-notes)  
12. [Testing](#testing)  
13. [Troubleshooting](#troubleshooting)  
14. [Security Checklist](#security-checklist)  
15. [Versioning](#versioning)

---

## Architecture

```
┌───────────────────────────┐
│       Your iOS App        │
│  (SwiftUI / UIKit, etc.)  │
└─────────────┬─────────────┘
              │
       AuthPackageUI.makeRoot()
              │
      ┌───────▼─────────┐
      │   AuthFlowView  │ 
      └───────┬─────────┘
              │ uses
      ┌───────▼─────────┐
      │ AuthViewModel   │ 
      └───────┬─────────┘
              ▼
         AuthClient facade
              │
        Services Layer
 (LoginService, TokenService, etc.)
              │
              ▼
       NetworkClient / URLSession
              │
              ▼
            Backend
```

- **Core (`AuthPackage`)**: provides typed API over backend endpoints.  
- **UI (`AuthPackageUI`)**: ships SwiftUI views, consumes the core client, applies style, and manages navigation.  
- **Router**: handles reset password deep-links and optional post-login redirect.  

---

## Installation (SPM)

1. **Xcode → File → Add Package Dependencies…**  
2. Enter repo URL:  
   ```
   https://github.com/YourOrg/AuthPackage-Swift.git
   ```  
3. Rule: **Up to Next Major Version** from `1.0.0`  
4. Add products:  
   - `AuthPackage`  
   - `AuthPackageUI`

Requirements: iOS 15+, Swift 5.9+, Xcode 16+

---

## Configuration

### Core

```swift
import AuthPackage

let core = AuthClient(
  config: AuthConfiguration(
    baseURL: URL(string: "https://api.example.com")!, // HTTPS required on device
    refreshUsesCookie: true, 
    redirectScheme: "myapp",     // keep for future OAuth
    microsoftEnabled: false      // disable OAuth in this version
  ),
  tokenStore: KeychainTokenStore(service: "com.example.app", account: "auth")
)
```

### UI

```swift
import SwiftUI
import AuthPackageUI

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      AuthPackageUI.makeRoot(
        config: AuthUIConfig(
          baseURL: URL(string: "https://api.example.com")!,
          appScheme: "myapp",
          microsoftEnabled: false,
          cssVariables: theme,  // theming (see below)
          postLoginDeeplink: URL(string: "myapp://home") // optional
        ),
        client: core
      )
    }
  }
}
```

- **cssVariables**: string with CSS-like tokens controlling colors, spacing, typography.  
- **postLoginDeeplink**: if provided, the UI opens this URL when auth succeeds; otherwise shows the packaged post-login screen.  

---

## Quick Start

### Email / Password Login
```swift
let claims = try await core.login(email: "user@test.com", password: "Secret123!")
```

### Logout
```swift
try await core.logout()
```

### Registration
```swift
let user = try await core.register(email: "new@test.com", password: "Secret123!", name: "New User")
```

### Password Reset
```swift
try await core.requestPasswordReset(email: "user@test.com")
try await core.resetPassword(token: "<token>", newPassword: "NewSecret!")
```

---

## Backend Contract

- `POST /api/auth/clients/login` → `{ accessToken, refreshToken }`  
- `POST /api/auth/refresh-token` → `{ accessToken }`  
- `POST /api/auth/logout`  
- `POST /api/auth/forgot-password`  
- `POST /api/auth/reset-password` (body: `{ token, password }`)  
- `POST /api/clients/register` → `{ id, email, name?, roles? }`  

---

## Public API

### AuthConfiguration
```swift
public struct AuthConfiguration: Sendable {
  public let baseURL: URL
  public let refreshUsesCookie: Bool
  public let redirectScheme: String?
  public let microsoftEnabled: Bool
}
```

### AuthClientProtocol Essentials
```swift
public protocol AuthClientProtocol {
  func login(email: String, password: String) async throws -> JWTClaims?
  func refreshIfNeeded() async throws -> String?
  func logout() async throws
  func register(email: String, password: String, name: String?, roles: [String]?) async throws -> User
  func requestPasswordReset(email: String) async throws -> String?
  func resetPassword(token: String, newPassword: String) async throws -> String?
  @MainActor
  func loginWithMicrosoft(from anchor: ASPresentationAnchor) async throws -> JWTClaims?
  var currentUser: User? { get }
  var tokens: Tokens? { get }
}
```

---

## Theming

Pass CSS-like tokens in `AuthUIConfig`:

```swift
let theme = """
:root {
  --authui-primary-color: #0a84ff;
  --authui-accent-color:  #34c759;
  --authui-background-color: #0b0b0b;
  --authui-text-color:     #ffffff;
  --authui-corner-radius: 16;
  --authui-spacing:       14;
  --authui-font-family:   Inter;
  --authui-title-size:    28;
  --authui-body-size:     17;
}
"""
```

Mapped areas:
- Primary / accent color  
- Background, text color  
- Corner radius, spacing  
- Font family + sizes  

---

## Post-Login Redirect

- Provide `postLoginDeeplink` in `AuthUIConfig`.  
- When `vm.isAuthenticated` flips, `AuthFlowView` calls `openURL(url)`.  
- Host app can catch the URL scheme to show a specific screen.  

---

## Error Handling

Errors normalized to `APIError`:
- `unauthorized` → “Invalid email or password”  
- `network` → connectivity/TLS  
- `server(status,message)` → backend error detail  
- `cancelled` → user aborted  

UI shows friendly alerts; logout errors are swallowed to avoid noise.

---

## Token Storage

- `InMemoryTokenStore()` — ephemeral  
- `KeychainTokenStore(service:account:)` — persistent, secure  
- Custom stores supported via `TokenStore` protocol.

---

## Platform Notes

- Simulator: `http://localhost:3000` works.  
- Device: requires **HTTPS** (use ngrok).  
- OAuth disabled by default in this version.

---

## Testing

- To force login every run:
```swift
#if DEBUG
try? KeychainTokenStore(service: "com.example.app", account: "auth").clear()
#endif
```

---

## Troubleshooting

- **UI doesn’t switch after login** → ensure you use `AuthPackageUI.makeRoot`.  
- **Logout shows errors** → update to latest UI, which clears forms & suppresses logout noise.  
- **Registration doesn’t return to login** → current UI shows a success alert, clears fields, then dismisses.

---

## Security Checklist

- Always use HTTPS in prod.  
- Store tokens in Keychain.  
- Keep JWT expiry short.  
- Don’t log tokens.  
- Use unique URL scheme.  

---

## Versioning

- Semantic Versioning (SemVer)  
- Breaking changes only in major releases  

---
---

© CisCode Internal — For private use within the organization.
