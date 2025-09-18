
# OAuth Providers

All providers follow the same high‑level pattern:

1. App opens backend route with `redirect=<app-scheme>://auth/callback`.
2. User signs in on the provider page.
3. Provider redirects to backend callback → backend issues tokens.
4. Backend redirects to `<app-scheme>://auth/callback?...`; package saves tokens.

## Microsoft

- Add Web redirect URIs for localhost, LAN IP, and tunnel in the Azure App.
- Optional claims recommended: `email`, `upn`, `preferred_username`.

## Google

- Create OAuth client in Google Cloud Console.
- Authorized redirect URIs for localhost/LAN/tunnel.
- Include `email` and `profile` scopes.

## Facebook

- Configure Facebook Login (Web) in Meta for Developers.
- Set valid OAuth redirect URIs for localhost/LAN/tunnel.
- Request `email` permission; in Live mode, whitelist testers.

## Native SDK Exchange (optional)

Use provider SDKs to obtain an ID token/code, then call your backend:

```http
POST /api/auth/{provider}/exchange  // → { accessToken, refreshToken }
```
