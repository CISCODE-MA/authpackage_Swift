
# Configuration

## ``AuthConfiguration`` (Core)
```swift
let core = AuthConfiguration(
  baseURL: URL(string: "https://api.example.com")!,
  refreshUsesCookie: true,
  redirectScheme: "authdemo",
  microsoftEnabled: true,
  googleEnabled: true,
  facebookEnabled: true
)
```

- `baseURL` — backend origin
- `refreshUsesCookie` — enable cookie-based refresh (backend support required)
- `redirectScheme` — your URL scheme for OAuth deep‑link return
- `microsoftEnabled / googleEnabled / facebookEnabled` — enable providers in the client

## ``AuthUIConfig`` (UI)
```swift
let ui = AuthUIConfig(
  baseURL: URL(string: "https://api.example.com")!,
  appScheme: "authdemo",
  microsoftEnabled: true,
  googleEnabled: true,
  facebookEnabled: true,
  postLoginDeeplink: URL(string: "authdemo://home")
  // cssVariables: """ /* optional theming tokens */ """
)
```

- `appScheme` — must match the Info.plist URL scheme
- `postLoginDeeplink` — opened after successful login (optional)
- `cssVariables` — optional CSS‑like theming tokens
