# Versioning & Releases

We use **Semantic Versioning**:
- Tag `vX.Y.Z` → pipeline publishes stable `X.Y.Z` (recommended for consumers).
- Push to `release` branch → pipeline can publish a pre-release
  `NEXT_MINOR.0-rc.YYYYMMDD.BUILDID` (if you enable that scheme).

Maintain a `CHANGELOG.md` and keep it updated per release.
