# CI/CD on Azure Pipelines

## What the pipeline does
- Runs **SwiftPM tests** on macOS.
- Exports **LCOV coverage** (and optional Cobertura).
- Publishes a zipped source artifact.
- (Optional) Publishes a Universal Package to **Azure Artifacts**.
- (Optional) SonarQube/Cloud analysis (toggle via variable).

## Minimal working pipeline (no Sonar by default)
```yaml
# azure-pipelines.yml
name: authpkg_release_$(Date:yyyyMMdd).$(Rev:r)
trigger:
  branches: { include: [ release ] }
pr:
  branches: { include: [ release ] }
pool: { vmImage: macos-latest }
variables: { CONFIG: release, SONAR_ENABLED: 'false' }
steps:
- checkout: self
  fetchDepth: 0
- script: |
    set -euo pipefail
    swift --version
    xcodebuild -version
  displayName: Show toolchain versions
- script: |
    set -euo pipefail
    swift test --enable-code-coverage
    if swift test --show-codecov-path >/dev/null 2>&1; then
      CODECOV_JSON_PATH=$(swift test --show-codecov-path | tail -n1)
      PROF_DIR=$(dirname "$CODECOV_JSON_PATH"); PROF="$PROF_DIR/default.profdata"
    else
      PROF=".build/debug/codecov/default.profdata"
    fi
    if swift test --show-test-binary-path >/dev/null 2>&1; then
      TEST_BIN=$(swift test --show-test-binary-path)
    else
      TEST_BIN=$(find .build -type f -name '*Tests' -perm -111 2>/dev/null | head -n1)
    fi
    xcrun llvm-cov export -format=lcov -instr-profile "$PROF" "$TEST_BIN" > coverage.lcov
  displayName: Build & test (with coverage)
- script: |
    set -euo pipefail
    rm -rf dist && mkdir -p dist/pkg
    cp -a Package.swift dist/pkg/
    [ -f Package.resolved ] && cp Package.resolved dist/pkg/ || true
    [ -d Sources ] && cp -a Sources dist/pkg/ || true
    [ -f README.md ] && cp README.md dist/pkg/ || true
    [ -f LICENSE ] && cp LICENSE dist/pkg/ || true
    [ -f coverage.lcov ] && cp coverage.lcov dist/pkg/ || true
    SHORT="${BUILD_SOURCEVERSION:0:7}"
    BRANCH="${BUILD_SOURCEBRANCHNAME//\//-}"
    pushd dist >/dev/null
    zip -rq "AuthPackage_src_${BRANCH}_${SHORT}.zip" pkg
    popd >/dev/null
  displayName: Create source artifact (.zip)
  condition: succeeded()
- task: PublishPipelineArtifact@1
  displayName: Publish artifact: AuthPackage (source zip)
  condition: succeeded()
  inputs:
    targetPath: dist
    artifact: AuthPackage
```

## Azure Artifacts (optional)
- Create an **Artifacts feed** (e.g. `ios-packages`) in Azure DevOps.
- Add a `UniversalPackages@0` publish step (feed GUID or name). Make sure the feed exists and you have permissions.
- For path-based issues (e.g. “dangerous Request.Path value with :”), avoid colons or unsafe characters in the **package version** or description fields.
