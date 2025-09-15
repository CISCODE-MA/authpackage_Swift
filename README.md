# AuthPackage (iOS / Swift) — Core + Drop‑in UI (Ultimate Guide)

> This guide is for iOS developers integrating **AuthPackage** into a fresh app. It covers
> installation, configuration, Microsoft OAuth, app URL schemes, common pitfalls, and a
> full end‑to‑end checklist. It **keeps the original Architecture section** (expanded below)
> and adds everything a new dev needs to ship.

---

## Table of Contents

1. [Architecture](#architecture)  
2. [Requirements](#requirements)  
3. [Installation (SPM)](#installation-spm)  
4. [Quick Start (copy‑paste)](#quick-start-copy-paste)  
5. [Configuration Reference](#configuration-reference)  
6. [App URL Scheme (Info.plist)](#app-url-scheme-infoplist)  
7. [Microsoft OAuth (Dev & Prod)](#microsoft-oauth-dev--prod)  
8. [Backend Contract (for reference)](#backend-contract-for-reference)  
9. [Using the Core Client Directly](#using-the-core-client-directly)  
10. [Token Storage & Refresh](#token-storage--refresh)  
11. [Post-Login Deeplink](#post-login-deeplink)  
12. [Troubleshooting](#troubleshooting)  
13. [Security Checklist](#security-checklist)  
14. [Versioning](#versioning)  
15. [Appendix: Minimal Host App Template](#appendix-minimal-host-app-template)

---

## Architecture

```
       ┌─────────────────────────────────────────────────┐
       │                   Your App                      │
       │  SwiftUI navigation, state, feature screens     │
       └───────────────────────▲─────────────────────────┘
                               │
                               │ consumes
                               │
       ┌───────────────────────┴─────────────────────────┐
       │                AuthPackageUI                     │
       │  Prebuilt flows (Login, Register, Forgot/Reset) │
       │  Theming (CSS-like vars), routing helpers       │
       └───────────────────────▲─────────────────────────┘
                               │
                               │ uses
                               │
       ┌───────────────────────┴─────────────────────────┐
       │                   AuthPackage                    │
       │  AuthClient facade                              │
       │  Services (LoginService, TokenService, etc.)    │
       │  Endpoints + NetworkClient (URLSession)         │
       └───────────────────────▲─────────────────────────┘
                               │
                               │ HTTP (JSON/JWT)
                               │
       ┌───────────────────────┴─────────────────────────┐
       │                    Backend                       │
       │  Express API + Passport (local + Microsoft)     │
       │  Issues app JWTs; stores refresh; deep-links    │
       └─────────────────────────────────────────────────┘
```

- **Core (`AuthPackage`)**: typed API over backend endpoints (login, refresh, logout, register, reset, Microsoft OAuth).  
- **UI (`AuthPackageUI`)**: SwiftUI screens using the core client; ships a drop‑in “auth flow”.  
- **Extensibility**: you can use the Core without the UI, or embed the UI and override visuals via theme variables.

---

## Requirements

- **Xcode** 16+  
- **iOS** 15.0+  
- **Swift** 5.9+  
- A reachable **auth backend** implementing the contract below

---

## Installation (SPM)

1. Xcode → **File** → **Add Package Dependencies…**  
2. Paste your repo URL:  
   ```
   https://github.com/YourOrg/AuthPackage-Swift.git
   ```
3. Rule: **Up to Next Major** from `1.0.0`  
4. Add products to your app target: **AuthPackage**, **AuthPackageUI**

---

## Quick Start (copy‑paste)

```swift
import SwiftUI
import AuthPackage
import AuthPackageUI

@main
struct MyApp: App {
  // Backend base URL:
  // - Simulator: http://localhost:3000
  // - Real device: http://<YOUR-MAC-LAN-IP>:3000  (or https://<your-tunnel>.ngrok.io)
  private let baseURL = URL(string: "http://localhost:3000")!

  private var ui: AuthUIConfig {
    AuthUIConfig(
      baseURL: baseURL,
      appScheme: "authdemo",       // must match Info.plist URL scheme
      microsoftEnabled: true,      // show the Microsoft button
      postLoginDeeplink: URL(string: "authdemo://home") // optional
    )
  }

  private var core: AuthConfiguration {
    AuthConfiguration(
      baseURL: baseURL,
      refreshUsesCookie: true,
      redirectScheme: "authdemo",  // required for Microsoft OAuth
      microsoftEnabled: true
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

> **Device vs Simulator**: a device **cannot** reach your Mac’s `localhost`. Use your LAN IP or an HTTPS tunnel, and ensure the backend & Azure app use that exact host.

---

## Configuration Reference

### `AuthUIConfig` (UI module)
- `baseURL: URL` — backend origin.
- `appScheme: String` — your app’s custom URL scheme (must be in Info.plist).
- `microsoftEnabled: Bool` — show/hide Microsoft button.
- `postLoginDeeplink: URL?` — open after success (optional).
- `cssVariables: String?` — theme tokens (optional; see theming below).

### `AuthConfiguration` (Core module)
- `baseURL: URL` — backend origin.
- `refreshUsesCookie: Bool` — allow refresh via HttpOnly cookie (backend support required).
- `redirectScheme: String?` — your URL scheme for Microsoft OAuth (required if `microsoftEnabled`).
- `microsoftEnabled: Bool` — enable Microsoft OAuth in the client.

> Keep `microsoftEnabled` **true in both configs** if you want the button visible **and** the client able to launch the flow.

---

## App URL Scheme (Info.plist)

Add a URL type with the scheme you referenced above (`authdemo` here):

```xml
<!-- Info.plist -->
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

This lets the backend deep‑link back: `authdemo://auth/callback?accessToken=...&refreshToken=...`

---

## Microsoft OAuth (Dev & Prod)

1) **Enable it**  
   - `AuthUIConfig.microsoftEnabled = true`  
   - `AuthConfiguration.microsoftEnabled = true`  
   - `AuthConfiguration.redirectScheme = "authdemo"` (same as Info.plist)

2) **Choose the right base URL**  
   - Simulator → `http://localhost:3000`  
   - Device → `http://<LAN-IP>:3000` or a tunnel → `https://<domain>/`  

3) **Azure app (server‑side setting you should verify with backend)**  
   - **Authentication → Platform: Web → Redirect URIs** must include the backend callback you actually use:  
     - `http://localhost:3000/api/auth/microsoft/callback` (simulator)  
     - `http://<LAN-IP>:3000/api/auth/microsoft/callback` (device on Wi‑Fi)  
     - `https://<tunnel>/api/auth/microsoft/callback` (device + HTTPS)  
   - (Recommended) **Token configuration → Optional claims**: add `email`, `upn`, `preferred_username` to avoid missing email claims.

4) **What “success” looks like**  
   - Microsoft web sheet opens → you sign in  
   - Microsoft returns to backend callback (approved reply URL)  
   - Backend 302’s to `authdemo://auth/callback?...`  
   - Sheet dismisses; the package parses/saves tokens; you’re authenticated

> If you see **AADSTS500113 (no reply address)**, the Azure app is missing the **exact** callback URI your backend sent. Add it to the Azure app and retry.

---

## Backend Contract (for reference)

> The UI/Core call these endpoints; you usually don’t need to call them yourself.

- `POST /api/auth/clients/login` → `{ accessToken, refreshToken }`  
- `POST /api/auth/refresh-token` → `{ accessToken }`  
- `POST /api/auth/logout`  
- `POST /api/auth/forgot-password`  
- `POST /api/auth/reset-password` (body: `{ token, password }`)  
- `POST /api/clients/register` → `{ id, email, name?, roles? }`  
- **Microsoft OAuth (web)**  
  - `GET /api/auth/microsoft?redirect=<app-scheme>://auth/callback`  
  - `GET /api/auth/microsoft/callback` → deep‑link with tokens  
- **Microsoft OAuth (native)** *(optional, when using MSAL)*  
  - `POST /api/auth/microsoft/exchange` (send Microsoft ID token; receive app tokens)

---

## Using the Core Client Directly

```swift
let client = AuthClient(config: core)

// Email/password
let claims = try await client.login(email: "user@example.com", password: "Secret123!")

// Microsoft OAuth (needs a presentation anchor)
import AuthenticationServices
guard let window = UIApplication.shared.connectedScenes
  .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first else { fatalError("No window") }
let msClaims = try await client.loginWithMicrosoft(from: window)

// Refresh if needed (returns non‑nil if refreshed)
let access = try await client.refreshIfNeeded()

// Logout
try await client.logout()
```

---

## Token Storage & Refresh

- Default storage is **in‑memory** (simple for dev).  
- For production, implement a `TokenStore` with **Keychain** and pass it to `AuthClient`.  
- `refreshIfNeeded()` uses the refresh token (or HttpOnly cookie, if enabled) to mint a new access token.

> Tip (dev): clear tokens on app start to force the login flow when testing.

---

## Post-Login Deeplink

If `postLoginDeeplink` is set on `AuthUIConfig`, the UI opens it after success. Handle the URL (e.g., `authdemo://home`) in your app to route to the right screen.

---

## Troubleshooting

**Microsoft page shows “No reply address is registered (AADSTS500113)”**  
- Azure app is missing the callback URL your backend used (`redirect_uri=`). Add the **exact** URL in Azure → Authentication.

**Web sheet loops after you enter email**  
- Callback mismatch or missing OIDC claims. Ensure Azure has the exact callback; add optional claims (email/upn/preferred_username).

**Sheet never dismisses to the app**  
- On a real device you’re still using `localhost` — switch `baseURL` to your LAN IP or tunnel.  
- Ensure Info.plist scheme matches `redirectScheme/appScheme`.

**Backend crash: `ValidationError: email is required` after Microsoft**  
- The ID token lacked an email-ish claim. Ask your admin to add optional claims in Azure, or pre‑create/link the user in DB.

**Microsoft button not visible**  
- Set `microsoftEnabled = true` in **both** UI and Core configs.

**Simulator works; device fails**  
- Device can’t reach your Mac’s `localhost`. Use LAN IP / tunnel and add the corresponding callback URL in Azure.

---

## Security Checklist

- Use **HTTPS** in production; enable ATS exceptions only for dev.  
- Store tokens in **Keychain** (implement a `TokenStore`).  
- Short‑lived access tokens; rotate refresh tokens.  
- Never log tokens.  
- Use a **unique** URL scheme; avoid overly generic names.  
- Limit CORS and allowed callback hosts on the backend.

---

## Versioning

- **SemVer**. Breaking changes only in **major** versions.  
- Each release includes a changelog entry.

---

## Appendix: Minimal Host App Template

```swift
import SwiftUI
import AuthPackage
import AuthPackageUI

@main
struct AuthDemoApp: App {
  var body: some Scene {
    WindowGroup {
      let base = URL(string: "http://localhost:3000")!   // device => LAN IP / tunnel
      let ui = AuthUIConfig(
        baseURL: base,
        appScheme: "authdemo",
        microsoftEnabled: true,
        postLoginDeeplink: URL(string: "authdemo://home")
      )
      let core = AuthConfiguration(
        baseURL: base,
        refreshUsesCookie: true,
        redirectScheme: "authdemo",
        microsoftEnabled: true
      )
      let client = AuthClient(config: core)
      AuthPackageUI.makeRoot(config: ui, client: client)
    }
  }
}
```

---

© Your Organization — Internal use.
