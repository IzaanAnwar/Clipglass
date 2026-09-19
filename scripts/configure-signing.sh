#!/usr/bin/env bash
set -euo pipefail
if [[ -z "${CERTIFICATE_BASE64:-}" ]]; then
    echo 'No Developer ID configured; producing a community build.'
    exit 0
fi
: "${CERTIFICATE_PASSWORD:?Required}"
: "${DEVELOPER_ID:?Required}"
: "${APPLE_ID:?Required}"
: "${APPLE_TEAM_ID:?Required}"
: "${APPLE_APP_PASSWORD:?Required}"
: "${RUNNER_TEMP:?Only run on an ephemeral CI runner}"
: "${GITHUB_ENV:?Required}"
certificate="$RUNNER_TEMP/clipglass-signing.p12"
keychain="$RUNNER_TEMP/clipglass-signing.keychain-db"
password=$(openssl rand -hex 24)
trap 'rm -f "$certificate"' EXIT
printf '%s' "$CERTIFICATE_BASE64" | base64 --decode > "$certificate"
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$certificate" -k "$keychain" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -k "$password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain"
xcrun notarytool store-credentials clipglass-notary --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" --keychain "$keychain"
printf 'SIGNING_IDENTITY=%s\nNOTARY_PROFILE=clipglass-notary\n' "$DEVELOPER_ID" >> "$GITHUB_ENV"
