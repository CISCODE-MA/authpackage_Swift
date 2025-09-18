
# Backend Contract

The client/UI call these endpoints:

- `POST /api/auth/clients/login` → `{ accessToken, refreshToken }`
- `POST /api/auth/refresh-token` → `{ accessToken }`
- `POST /api/auth/logout`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `POST /api/clients/register`

**OAuth (web-backed)**

- `GET /api/auth/{provider}?redirect=<scheme>://auth/callback`
- `GET /api/auth/{provider}/callback` → 302 to `<scheme>://auth/callback?...`

**OAuth (native exchange)**

- `POST /api/auth/{provider}/exchange` with `{ idToken }` → `{ accessToken, refreshToken }`
