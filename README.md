# AuthPackage - Swift 

A clean, scalable Swift Package that provides authentication features for iOS/macOS apps.  
It is designed with **SOLID principles** and a **separation of concerns** (SoC) in mind, making it easy to integrate into any project and extend in the future.

## ✨ Features

- 🔑 User registration, email verification
- 🔐 Login with password + OTP (two-step authentication)
- 🔄 Token refresh and validation
- 🔓 Password reset
- 🧰 Token persistence via in-memory or Keychain storage
- ⚙️ Configurable base URL for different environments (dev, staging, prod)
- ✅ Written with Swift Concurrency (`async/await`)

---

## 📦 Installation

### Swift Package Manager

Add this package to your Xcode project:

1. Go to **File > Add Package Dependencies…**  
2. Enter the repo URL:  
```bash 
https:github.com/Zaiidmo/AuthPackage-Swift.git 
```
3. Choose **Up to Next Major Version** from `1.0.0`.

---

## 🚀 Usage

### 1. Configure the client
```swift
import AuthPackage

let config = AuthConfiguration(baseURL: URL(string: "http://localhost:3000")!)
let tokenStore = KeychainTokenStore(service: "com.yourapp.auth", account: "auth_tokens")

let authClient = AuthClient(config: config, tokenStore: tokenStore)
```
### 2. Register a new user
```swift
let user = try await authClient.register(
    fname: "John",
    lname: "Doe",
    username: "johndoe",
    email: "john@example.com",
    phone: "+1234567890",
    password: "supersecure",
    roles: ["user"]
)

```
### 3. Login + OTP flow
```swift 
// Step 1: initiate login
let (otpSentTo, _) = try await authClient.loginStart(
    identifier: "john@example.com",
    password: "supersecure",
    rememberMe: true
)
// Show OTP entry UI to user

// Step 2: verify OTP
let loggedInUser = try await authClient.verifyOTP(
    identifier: "john@example.com",
    otp: "123456"
)
```
### 4. Refresh session
```swift
try await authClient.refreshIfNeeded()
```
### 5. Logout
```swift 
try await authClient.logour()
```

---

## 🗂 Project Structure 
```bash
Sources/
 └─ AuthPackage/
     ├─ Core/           # Base utilities: network, token storage, config
     ├─ Domain/         # Models and DTOs (pure Swift types)
     ├─ Data/           # API endpoints + services (Login, OTP, etc.)
     └─ Facade/         # Single entry point: AuthClient
Tests/
 └─ AuthPackageTests/   # Unit tests for client and services
 ```

---

## 🧪 Running Tests
```bash
swift test 
 ``` 
 
Make sure you have Xcode 16.1+ (Swift 6.1) installed and selected:
```bash 
sudo xcode-select -s /Applications/Xcode.app
swift --version```

---

## 📌 Roadmap
* v1.0.0 → Core authentication logic (this version)

* v1.1.0 → Optional UI components (SwiftUI views for Login, OTP, etc.)

* v2.0.0 → Advanced features (social logins, biometric helpers, role-based access)
