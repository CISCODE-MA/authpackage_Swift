# AuthPackage (iOS / Swift)

**Typed core client + Drop‑in SwiftUI auth.**  
Supports email/password and **Microsoft, Google, Facebook** OAuth.  
Backend-agnostic (Express sample), testable, and CI‑ready.

## Quick Start
```swift
import SwiftUI
import AuthPackage
import AuthPackageUI

@main
struct MyApp: App {
  private let baseURL = URL(string: "http://localhost:3000")!
  private var ui: AuthUIConfig {
    AuthUIConfig(
      baseURL: baseURL,
      appScheme: "authdemo",
      microsoftEnabled: true, googleEnabled: true, facebookEnabled: true,
      postLoginDeeplink: URL(string: "authdemo://home")
    )
  }
  private var core: AuthConfiguration {
    AuthConfiguration(
      baseURL: baseURL, refreshUsesCookie: true, redirectScheme: "authdemo",
      microsoftEnabled: true, googleEnabled: true, facebookEnabled: true
    )
  }
  var body: some Scene {
    WindowGroup { AuthPackageUI.makeRoot(config: ui, client: AuthClient(config: core)) }
  }
}
```

> Device can’t reach your Mac’s `localhost` — use your LAN IP or a tunnel and configure the same host in OAuth provider + backend callbacks.

## Architecture (high level)
```
Your App (SwiftUI) → AuthPackageUI (Flows/Theming) → AuthPackage (Services/Client) → Backend (Express+Passport) → Providers
```

## Documentation
- 👉 **[Installation Guide](docs/installation-guide.md)**
- 👉 **[Configuration](docs/configuration.md)** (Core, UI, TokenStore, theming)
- 👉 **[OAuth Providers](docs/oauth-providers.md)** (Microsoft / Google / Facebook)
- 👉 **[Backend Contract](docs/backend-contract.md)**
- 👉 **[CI/CD on Azure Pipelines](docs/ci-cd-azure.md)**
- 👉 **[Versioning & Releases](docs/versioning-releases.md)**
- 👉 **[Troubleshooting](docs/troubleshooting.md)**
- 👉 **[Security Checklist](docs/security.md)**
- 👉 **[Contributing](../CONTRIBUTING.md)**

## License
MIT — see [LICENSE](../LICENSE).
