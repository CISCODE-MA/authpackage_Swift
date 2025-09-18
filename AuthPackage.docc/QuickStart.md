
# Quick Start

Set up both Core (``AuthConfiguration``) and UI (``AuthUIConfig``) then make the UI root.

```swift
import SwiftUI
import AuthPackage
import AuthPackageUI

@main
struct MyApp: App {
  private let baseURL = URL(string: "http://localhost:3000")! // Use LAN IP/tunnel on device

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

> Devices can’t reach `localhost`. On a real device, use your Mac's LAN IP or an HTTPS tunnel and configure the backend and provider apps with that exact host.
