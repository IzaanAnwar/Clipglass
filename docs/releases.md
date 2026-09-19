# Release process

1. Update VERSION using `major.minor.patch` and document changes in CHANGELOG.md.
2. Run tests, build the app, and verify the DMG. Merge to main with passing CI.
3. Create and push an annotated tag matching VERSION, for example `git tag -a v0.2.0 -m 'Clipglass 0.2.0'`, then `git push origin v0.2.0`.
4. The Release workflow tests, builds arm64 and x86_64 into a universal app, verifies signatures and the DMG, then creates a GitHub Release with a DMG and SHA-256 checksum.

Tags are immutable release identifiers. Fix a bad release with a new version; do not replace published assets. Builds use Xcode 26.6 on the macos-26 GitHub runner. Actions are pinned by commit and updated through Dependabot. CI for pull requests has read-only permissions and no signing secrets. Only the publishing job has contents write access.

## Signing

Without signing secrets, releases are ad-hoc signed community builds and explicitly labeled as not notarized. They are downloadable, but macOS Gatekeeper may block opening them. Do not describe these builds as Apple-verified.

To enable Developer ID signing and notarization, configure repository Actions secrets:

- MACOS_CERTIFICATE_BASE64: base64-encoded Developer ID Application certificate and private key exported as a .p12
- MACOS_CERTIFICATE_PASSWORD: export password
- MACOS_SIGNING_IDENTITY: full Developer ID Application identity
- APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD: notarization account credentials

The workflow imports credentials into a temporary runner keychain, signs with hardened runtime, submits the DMG to Apple, staples the notarization ticket, and deletes the keychain. A partially configured signing setup fails the release rather than silently producing an unsigned asset.

Locally, set SIGNING_IDENTITY and NOTARY_PROFILE to use an existing Developer ID and notarytool keychain profile. Never commit credentials.
