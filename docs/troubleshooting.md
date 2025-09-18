# Troubleshooting

- **Invalid/unknown redirect URI**  
  The provider app is missing the exact backend callback you’re using. Add the URI in the provider console.

- **OAuth sheet loops after entering email**  
  Hostname mismatch between app, backend, and provider settings or missing email claim/scope. Use the same base host the device can reach. Ensure `email`/`profile` scopes for Google, `email` permission for Facebook, and `email`/`upn`/`preferred_username` across Microsoft.

- **Deep-link never opens the app**  
  Info.plist scheme doesn’t match `appScheme`/`redirectScheme`. Fix the scheme, clean install the app, retry.

- **Device can’t sign in but simulator works**  
  Device can’t reach `localhost`. Use `http://<LAN-IP>:3000` or a tunnel; update provider and backend callback URLs.

- **Backend `ValidationError: email is required` after OAuth**  
  Provider profile lacked a usable email. Add/approve scopes/permissions or link/pre-create the user in your backend.

- **Azure Artifacts publish fails with “dangerous Request.Path value (:)”**  
  Remove colons or unsafe characters from the version and description; prefer `1.2.0-rc.20250918.1`.
