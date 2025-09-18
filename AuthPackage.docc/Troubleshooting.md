
# Troubleshooting

- **No reply address (AADSTS500113)** — The Azure app is missing the exact backend callback URL; add it.
- **OAuth sheet loops after email** — Hostname mismatch or missing claims/scopes.
- **Deep‑link never opens** — Info.plist scheme doesn’t match `appScheme`/`redirectScheme`.
- **Simulator works, device fails** — Devices cannot reach `localhost`; use LAN IP or tunnel everywhere.
- **Backend says `email is required` after OAuth** — Provider profile lacked a usable email; add/approve the proper scopes/permissions.
