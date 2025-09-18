# Security Checklist

- Use **HTTPS** in production (disable ATS exceptions outside dev).
- Store tokens in **Keychain** (custom `TokenStore`).
- Keep access tokens short-lived; rotate refresh tokens.
- Never log tokens or secrets.
- Use a **unique URL scheme** (avoid generic names to prevent hijacking).
- Restrict CORS and allowed callback hosts on the backend.
- Protect refresh endpoints; monitor suspicious token reuse.
