# AuthPackage Documentation

Welcome! This folder contains the **task-oriented guides** for integrating and operating AuthPackage.
If you're new, follow the **Golden Path** below; otherwise jump to any guide.

## Golden Path (10 minutes)
1. **[Installation Guide](installation-guide.md)** — add the package, set iOS URL scheme, run on device.
2. **[Configuration](configuration.md)** — set `AuthConfiguration` + `AuthUIConfig`.
3. **[OAuth Providers](oauth-providers.md)** — wire Microsoft / Google / Facebook on the backend and in the app.
4. **[Backend Contract](backend-contract.md)** — endpoints & JSON payloads.
5. **[Troubleshooting](troubleshooting.md)** — common issues & fixes.

---

## All Guides

- **Start**
  - [Installation Guide](installation-guide.md)
  - [Configuration](configuration.md)
  - [OAuth Providers](oauth-providers.md)
  - [Backend Contract](backend-contract.md)

- **Operate**
  - [Troubleshooting](troubleshooting.md)
  - [Security Checklist](security.md)
  - [CI/CD on Azure Pipelines](ci-cd-azure.md)
  - [Versioning & Releases](versioning-releases.md)
  - [API Quick Reference](api-quickref.md)
  - [Migration Notes](migration-notes.md)

---

## Architecture (at a glance)

```mermaid
flowchart LR
  A[Your App (SwiftUI)] --> B[AuthPackageUI<br/>Flows + Theming]
  B --> C[AuthPackage Core<br/>AuthClient + Services + Network]
  C --> D[(Backend API)]
  D --> E[[OAuth Providers<br/>Microsoft / Google / Facebook]]
  ```
  
### /docs/api-quickref.md
```markdown
# API Quick Reference

> For full symbol-level docs, prefer DocC; this page is a concise cheat sheet for day-to-day use.

## Core Types

### `AuthConfiguration`
```swift
public struct AuthConfiguration {
  public var baseURL: URL
  public var refreshUsesCookie: Bool
  public var redirectScheme: String?      // required when any OAuth provider is enabled
  public var microsoftEnabled: Bool
  public var googleEnabled: Bool
  public var facebookEnabled: Bool
}```

