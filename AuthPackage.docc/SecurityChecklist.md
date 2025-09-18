
# Security Checklist

- Use HTTPS in production; restrict ATS exceptions to development.
- Store tokens in **Keychain** via a custom ``TokenStore``.
- Keep access tokens short‑lived; rotate refresh tokens.
- Never log tokens.
- Use a unique URL scheme; avoid generic names.
- Lock down backend CORS and allowed callback hosts.
