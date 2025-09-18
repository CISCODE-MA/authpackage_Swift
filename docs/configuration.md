# Configuration

## Core (`AuthConfiguration`)
```swift
let core = AuthConfiguration(
  baseURL: URL(string: "https://api.example.com")!,
  refreshUsesCookie: true,
  redirectScheme: "authdemo",             // required when any OAuth provider is enabled
  microsoftEnabled: true,
  googleEnabled: true,
  facebookEnabled: true
)
```

## UI (`AuthUIConfig`)
```swift
let ui = AuthUIConfig(
  baseURL: URL(string: "https://api.example.com")!,
  appScheme: "authdemo",
  microsoftEnabled: true,
  googleEnabled: true,
  facebookEnabled: true,
  // Optional theming via CSS-like tokens
  // cssVariables: """
  //   --authui-background-color: #0B132B;
  //   --authui-primary-color: #5BC0BE;
  // """
  postLoginDeeplink: URL(string: "authdemo://home")
)
```

## Token Storage
- Default is **in-memory** (dev-friendly).
- For production, implement a `TokenStore` backed by **Keychain** and inject it into `AuthClient`.

## Using the Core Client
```swift
let client = AuthClient(config: core)
// Email/password
let claims = try await client.login(email: "user@example.com", password: "Secret123!")
// OAuth (ASWebAuthenticationSession - provide UI anchor)
let window = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first!
let ms = try await client.loginWithMicrosoft(from: window)
let gg = try await client.loginWithGoogle(from: window)
let fb = try await client.loginWithFacebook(from: window)
// Refresh / logout
let access = try await client.refreshIfNeeded()
try await client.logout()
```
