# Installation Guide

## Requirements
- Xcode 16+, iOS 15.0+, Swift 5.9+
- Reachable auth backend (see Backend Contract)

## Add via Swift Package Manager
1. Xcode → **File** → **Add Package Dependencies…**
2. Paste the repository URL.
3. Rule: **Up to Next Major** from `1.0.0`.
4. Add products to your target: **AuthPackage**, **AuthPackageUI**.

## App URL Scheme (Info.plist)
Add a URL type with your chosen scheme (`authdemo` example):
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

## Device vs Simulator
- **Simulator:** `http://localhost:3000` is fine.
- **Physical device:** use `http://<LAN-IP>:3000` or a tunnel (https) and configure the *same host* in provider apps and backend callback URLs.
