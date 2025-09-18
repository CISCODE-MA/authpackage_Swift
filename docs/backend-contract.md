# Backend Contract

- `POST /api/auth/clients/login` → `{ accessToken, refreshToken }`
- `POST /api/auth/refresh-token`  → `{ accessToken }`
- `POST /api/auth/logout`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password` (body: `{ token, password }`)
- `POST /api/clients/register`    → `{ id, email, name?, roles? }`

**OAuth (web-backed):**
- `GET /api/auth/microsoft?redirect=<app-scheme>://auth/callback`
- `GET /api/auth/google?redirect=<app-scheme>://auth/callback`
- `GET /api/auth/facebook?redirect=<app-scheme>://auth/callback`
- `GET /api/auth/<provider>/callback` → 302 → `<app-scheme>://auth/callback?...`

**OAuth (native exchange):**
- `POST /api/auth/<provider>/exchange` with `{ idToken }` → `{ accessToken, refreshToken }`
