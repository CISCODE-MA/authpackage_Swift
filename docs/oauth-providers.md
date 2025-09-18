# OAuth Providers

All providers use the same pattern:

1. App opens backend route with `redirect` to your app scheme:  
   `GET /api/auth/<provider>?redirect=authdemo://auth/callback`
2. Provider login → backend callback → backend mints app tokens.
3. Backend **302** to `authdemo://auth/callback?...` with tokens.
4. App saves tokens and continues.

## Microsoft
- Azure AD App → Authentication → **Web** redirect URIs:
  - `http://localhost:3000/api/auth/microsoft/callback`
  - `http://<LAN-IP>:3000/api/auth/microsoft/callback`
  - `https://<tunnel>/api/auth/microsoft/callback`
- Ensure an email-ish claim exists (`email`, `upn`, or `preferred_username`).

## Google
- Google Cloud Console → OAuth consent + Credentials → **Web client** for backend.
- Authorized redirect URIs:
  - `http://localhost:3000/api/auth/google/callback`
  - `http://<LAN-IP>:3000/api/auth/google/callback`
  - `https://<tunnel>/api/auth/google/callback`
- Scopes: include `email` and `profile`.

## Facebook
- Meta for Developers → Facebook Login (Web).
- Valid OAuth Redirect URIs:
  - `http://localhost:3000/api/auth/facebook/callback`
  - `http://<LAN-IP>:3000/api/auth/facebook/callback`
  - `https://<tunnel>/api/auth/facebook/callback`
- Permissions: request `email`. In Live mode, whitelist testers.

## Native SDK (optional)
Use GoogleSignIn / FBSDK / MSAL to obtain an **ID token** (or code), then call backend:
```
POST /api/auth/<provider>/exchange  // → { accessToken, refreshToken }
```
