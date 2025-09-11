# AuthPackage (iOS / Swift) — Comprehensive Guide

> **Purpose**  
> A production‑ready Swift package that plugs into your company’s Express‑based auth service. It provides a clean facade for **email/password**, **token refresh/logout**, **password reset**, **client registration**, and **Microsoft OAuth via your backend** using deep‑links — with minimal setup in a new iOS app.

---

## Table of Contents

1. [At a Glance](#at-a-glance)  
2. [Architecture](#architecture)  
3. [Installation (SPM)](#installation-spm)  
4. [Configuration](#configuration)  
5. [Quick Start](#quick-start)  
6. [Backend Contract (HTTP API)](#backend-contract-http-api)  
7. [Public API (Swift)](#public-api-swift)  
8. [Error Handling](#error-handling)  
9. [Token Storage](#token-storage)  
10. [Microsoft OAuth (via Backend)](#microsoft-oauth-via-backend)  
11. [Platform Notes](#platform-notes)  
12. [Troubleshooting & FAQ](#troubleshooting--faq)  
13. [Testing](#testing)  
14. [Migration Notes](#migration-notes)  
15. [Security Checklist](#security-checklist)  
16. [Versioning](#versioning)

---

## At a Glance

- **Drop‑in** auth client for your company’s Node/Express auth service.  
- Small surface area: `login`, `register`, `refreshIfNeeded`, `logout`, password reset, and Microsoft OAuth.  
- **Config‑based**: point to a `baseURL`, choose token store, optionally enable OAuth.  
- **Safe defaults**: JSON over HTTPS, strict error mapping, Keychain storage recommended.  
- **No tenant** in client API (email+password only), aligned with backend “clients” routes.

---

## Architecture

```
┌─────────────────────────┐
│      Your iOS App       │
│  (SwiftUI / UIKit etc.) │
└───────────┬─────────────┘
            │ AuthClient (Facade)
            │    -Configuration-
            ▼
        ┌─────────────────────────┐
        │ AuthPackage Interfaces  │
        │  (Swift UI)             │
        └───┬─────────────────────┘
            │  
            ▼
    ┌───────────────────────┐
    │   Services Layer      │  LoginService / TokenService /
    │  (domain-specific)    │  RegistrationService / PasswordResetService
    └───────────┬───────────┘
                │
                ▼
       NetworkClient (URLSession)
                │
                ▼
             Backend
```

- **AuthClient** is the entry point you use in app code.  
- **Services** shape requests & responses for specific flows.  
- **NetworkClient** encapsulates `URLSession` and error mapping.  
- **TokenStore** abstracts where tokens live (Keychain recommended).

---

## Installation (SPM)

1. Go to **File > Add Package Dependencies…**  
2. Enter the repo URL:  
```bash 
https://github.com/Zaiidmo/AuthPackage-Swift.git 
```
3. Choose **Up to Next Major Version** from `1.0.0`.
4. Minimums: **iOS 15+**, **Swift 5.9+**, **Xcode 16+**.

---

## Configuration

```swift
import AuthPackage

let config = AuthConfiguration(
  baseURL: URL(string: "http://localhost:3000")!, // dev; use HTTPS in prod / on device
  refreshUsesCookie: true,                        // server may set refreshToken cookie
  redirectScheme: "authdemo",                     // required for OAuth
  microsoftEnabled: true                          // surface the OAuth entry point
)

let tokens = KeychainTokenStore(service: "com.your.bundle", account: "auth") // recommended
let auth = AuthClient(config: config, tokenStore: tokens)
```

> **URL Scheme (OAuth)**: Add your scheme (e.g., `authdemo`) under **Target → Info → URL Types**.  
> For devices, don’t use `localhost`. Use your Mac’s LAN IP or an HTTPS tunnel (e.g., ngrok).

---

## Quick Start

### Email/Password Login

```swift
let claims = try await auth.login(email: "user@company.com", password: "Secret123!")
// Access token saved; claims optionally decoded for convenience.
```

### Refresh & Logout

```swift
let maybeNewAccess = try await auth.refreshIfNeeded()
try await auth.logout()
```

### Password Reset

```swift
try await auth.requestPasswordReset(email: "user@company.com")
try await auth.resetPassword(token: "<email-token>", newPassword: "NewSecret!")
```

### Client Registration

```swift
let user = try await auth.register(
  email: "new@client.com",
  password: "Secret123!",
  name: "New Client",
  roles: ["admin"] // optional
)
```

### Microsoft OAuth (via Backend)

```swift
import AuthenticationServices

@MainActor
func signInWithMicrosoft(from window: ASPresentationAnchor) async {
  do {
    _ = try await auth.loginWithMicrosoft(from: window)
    // Tokens are saved in tokenStore; claims decoded on return
  } catch {
    // handle error
  }
}
```

---

## Backend Contract (HTTP API)

**Auth (Clients)**  
- `POST /api/auth/clients/login`  
  **Body**: `{ email, password }` → **200** `{ accessToken, refreshToken }`

- `POST /api/auth/refresh-token`  
  Cookie `refreshToken` or **Body** `{ refreshToken }` → **200** `{ accessToken }`

- `POST /api/auth/logout`  
  **200** `{ message }`

**Password Reset**  
- `POST /api/auth/forgot-password` → **Body** `{ email }` → **200** `{ message }`  
- `POST /api/auth/reset-password` → **Body** `{ token, password }` → **200** `{ message }`

**Client Registration**  
- `POST /api/clients/register`  
  **Body** `{ email, password, name?, roles? }` → **201** `{ id, email, name?, roles? }`

**Microsoft OAuth** (mobile + web)  
- `GET /api/auth/microsoft?redirect=<scheme>://auth/callback`  
  Server round‑trips `redirect` via `state` to Microsoft.
- `GET /api/auth/microsoft/callback?...state=...`  
  On success: sign tokens; if mobile redirect is present, `302` to  
  `<scheme>://auth/callback?accessToken=...&refreshToken=...`  
  Otherwise return JSON for web.

> These are the routes used by the package’s default `Endpoints`.

---

## Public API (Swift)

### `AuthConfiguration`

```swift
public struct AuthConfiguration: Sendable {
  public let baseURL: URL
  public let refreshUsesCookie: Bool
  public let redirectScheme: String?      // required for OAuth
  public let microsoftEnabled: Bool
}
```

### `AuthClientProtocol` Essentials

```swift
public protocol AuthClientProtocol {
  // Core
  func login(email: String, password: String) async throws -> JWTClaims?
  func refreshIfNeeded() async throws -> String?
  func logout() async throws

  // Registration
  func register(email: String, password: String, name: String?, roles: [String]?) async throws -> User

  // Password reset
  func requestPasswordReset(email: String) async throws -> String?
  func resetPassword(token: String, newPassword: String) async throws -> String?

  // OAuth (Microsoft via backend)
  @MainActor
  func loginWithMicrosoft(from anchor: ASPresentationAnchor) async throws -> JWTClaims?

  // State
  var currentUser: User? { get }
  var tokens: Tokens? { get }
}
```

### Models

```swift
public struct User: Codable, Equatable, Sendable {
  public let id: String
  public let email: String
  public let name: String?
  public let tenantId: String?
  public let roles: [String]
  public let permissions: [String]
}

public struct Tokens: Codable, Equatable, Sendable {
  public var accessToken: String
  public var refreshToken: String?
  public var expiry: Date?
}
```

---

## Error Handling

Errors are normalized to `APIError`:

```swift
public enum APIError: Error {
  case invalidURL
  case network(URLError)                     // connectivity / TLS
  case server(status: Int, message: String?) // backend responded 4xx/5xx
  case decodingFailed
  case unauthorized
  case cancelled
  case unknown
}
```

**Tips**
- Inspect `server(status:message:)` for backend rejections (e.g., 400 “Incorrect email”).  
- Treat `unauthorized` as “login required or token expired”.  
- `cancelled` is returned when a user dismisses the OAuth web sheet.

---

## Token Storage

Two built‑ins:

- `InMemoryTokenStore()` — ephemeral; great for tests or preview.  
- `KeychainTokenStore(service:account:)` — secure persistent storage.

Bring your own by conforming to:

```swift
public protocol TokenStore {
  func save(_ tokens: Tokens) throws
  func load() throws -> Tokens?
  func clear() throws
}
```

---

## Microsoft OAuth (via Backend)

**Flow**
1. Package opens `GET /api/auth/microsoft?redirect=<scheme>://auth/callback` with `ASWebAuthenticationSession`.  
2. Server stores `redirect` inside `state` and sends to Microsoft.  
3. On callback, server issues tokens; if mobile redirect present → `302` to `<scheme>://auth/callback?...`.  
4. Web auth session auto‑closes; tokens parsed and saved.

**iOS Setup**
- Add URL scheme, set `redirectScheme` in `AuthConfiguration`.  
- Use a valid `ASPresentationAnchor` (window) for the session.  
- Prefer **HTTPS** in production; for devices use LAN IP or HTTPS tunnel.

**Troubleshooting**
- Sheet loops / asks email again → the flow didn’t reach backend callback (check Azure tenant/endpoint v1 vs v2).  
- Sheet doesn’t close → no deep‑link reached the app (bridge or callback needs to redirect to your scheme).  
- Tokens missing on return → check the query keys `accessToken`, `refreshToken`.

---

## Platform Notes

- **Simulator** can call `http://localhost:3000`. iOS will warn that `http` is deprecated for web auth; okay for dev.  
- **Physical device** cannot reach `localhost` on your Device: use **LAN IP** or **ngrok HTTPS**.  
- **Cookies**: when `refreshUsesCookie` is `true`, the server may also set a `refreshToken` cookie; package still accepts a token in JSON body for refresh.

---

## Troubleshooting & FAQ

**Q: I get `Incorrect email` or 400 from `/login`.**  
A: Confirm you’re posting to `/api/auth/clients/login` with `{ email, password }`. No tenant required.

**Q: OAuth sheet loops back to Microsoft or won’t close.**  
A: Confirm **init** adds `state` and **callback** redirects to `<scheme>://auth/callback?...`. From a terminal:  
`curl -I "<base>/api/auth/microsoft?redirect=<scheme>://auth/callback" | grep -i location` should show `state=`.  
Opening that URL in Safari should prompt **“Open in <YourApp>?”** after sign‑in.

**Q: Device testing fails.**  
A: Replace `localhost` with your Device's' **LAN IP** or `https://<ngrok>.ngrok-free.app` for both app `baseURL` and server `MICROSOFT_CALLBACK_URL`.

**Q: Refresh fails due to cookie policies.**  
A: The package also accepts a body `{ refreshToken }`. Ensure `JWT_REFRESH_SECRET` is set server‑side.

---

## Testing

### Live Smoke Test (optional)
```bash
export LIVE_BASE_URL=http://localhost:3000
export LIVE_EMAIL=a@b.com
export LIVE_PASSWORD=Secret123!
swift test --filter LiveAuthTests
```

### Unit Tests (recommended)
- Mock `NetworkClient` (return canned JSON/status).  
- Use `InMemoryTokenStore` to verify persistence behavior.  
- Cover:
  - `LoginService` happy/negative paths  
  - `TokenService` refresh (cookie and body) + logout  
  - `RegistrationService` mapping of top‑level `{ id, email, name, roles }`  
  - `PasswordResetService` request + reset  
  - OAuth method: inject a fake authenticator that returns `Tokens` (no UI).

---

## Migration Notes

- **Removed tenant from client API**: login accepts only `{ email, password }`.  
- **User model** unified: `{ id, email, name?, tenantId?, roles[], permissions[] }`.  
- Registration maps the top‑level response from `/api/clients/register` into `User`.

---

## Security Checklist

- [ ] Always use **HTTPS** in production.  
- [ ] Store tokens in **Keychain**.  
- [ ] Keep JWT lifetimes short; refresh often.  
- [ ] Validate backend TLS certificates in production.  
- [ ] Avoid logging raw tokens; mask when debugging.  
- [ ] Lock down app URL scheme to a unique string.

---

## Versioning

- Follow **SemVer**.  
- Breaking changes in major versions (e.g., model shapes, public API signatures).  
- Keep a `CHANGELOG.md` for release notes.

---

© Company Internal — For private use within the organization.
