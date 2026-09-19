#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
VERSION="${VERSION:-$(cat VERSION)}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid version' >&2; exit 1; }
APP="$PROJECT_ROOT/dist/Clipglass.app"
[[ -d "$APP" ]] || { echo 'Run scripts/build-app.sh first.' >&2; exit 1; }
actual=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
[[ "$actual" == "$VERSION" ]] || { echo 'App version does not match release version.' >&2; exit 1; }
staging=$(mktemp -d "${TMPDIR:-/tmp}/clipglass-dmg.XXXXXX")
trap 'rm -rf "$staging"' EXIT
ditto "$APP" "$staging/Clipglass.app"
ln -s /Applications "$staging/Applications"
cp LICENSE "$staging/License.txt"
printf 'Drag Clipglass to Applications, then open it.\nEnable Accessibility in Clipglass Settings for direct paste.\n' > "$staging/Read me.txt"
DMG="$PROJECT_ROOT/dist/Clipglass-$VERSION.dmg"
hdiutil create -volname "Clipglass $VERSION" -srcfolder "$staging" -ov -format UDZO "$DMG"
hdiutil verify "$DMG"
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
fi
(cd dist && shasum -a 256 "Clipglass-$VERSION.dmg" > "Clipglass-$VERSION.dmg.sha256")
echo "Packaged $DMG"
