# Clipglass

A small, native macOS clipboard manager. Find something you copied, choose it, and paste it into the field you were editing.

[Download the latest release](https://github.com/IzaanAnwar/Clipglass/releases/latest) · [All versions](https://github.com/IzaanAnwar/Clipglass/releases) · [MIT license](LICENSE)

Requires macOS 26 or later. Release DMGs contain a universal Apple silicon / Intel app. Community releases are ad-hoc signed unless their release notes explicitly say notarized; macOS may block downloaded community builds.

## Use

Drag Clipglass from the DMG to Applications, then open it. A clipboard icon appears in the menu bar.

| Shortcut | Action |
| --- | --- |
| Control–Option–V | Open or close history from anywhere; customizable in Settings |
| Up / Down | Select an item |
| Return or click | Paste the item into the original editable field |
| Command–1 through Command–9 | Paste the corresponding visible item while Clipglass is open |
| Command–Return | Copy only |
| Command–comma | Settings |
| Escape | Close, or cancel shortcut recording |

In Settings, click the open-shortcut button and press a new combination. Common editing shortcuts are reserved; unavailable combinations leave the existing shortcut intact. The numbered shortcuts can use Command, Option, or Control–Option. They do not override shortcuts in other apps.

Enable Accessibility in Settings for direct paste. Clipglass checks the original focused field, waits for shortcut modifiers to be released, and sends Paste only if that same field remains editable. Non-editable, secure, and unsupported targets are left alone. Some custom editors do not expose enough accessibility information; use Command–Return to copy in those cases. Direct paste never presses Return or submits a form.

## History and privacy

25 items by default, configurable from 1 to 10,000, with a 128 MB retained-content limit. Text, rich text, HTML, links, PNG/TIFF images, and file references are supported. File entries reference the original files, which must still exist. App-specific formats and promised files are not captured. Polling runs every 0.4 seconds, so copies made faster than that can be missed.

History is saved in `~/Library/Application Support/Clipglass/history.sqlite`. SQLite transactions and full synchronization preserve committed history across restarts and crashes. Normal quit waits for pending saves. An abrupt crash can lose a change still waiting to be committed. Clear History removes saved records; it does not change the current system clipboard or erase external backups.

No accounts, telemetry, or cloud sync. The database is owner-readable and not app-encrypted. Confidential clipboard markers are respected, but unmarked secrets cannot be detected reliably. See [security and privacy](SECURITY.md).

## Build and test

Requires Swift 6.2+, a macOS 26+ SDK, and macOS. No third-party runtime dependencies; SQLite is provided by the system.

```sh
./scripts/test.sh
./scripts/build-app.sh
open dist/Clipglass.app
```

For a universal app and disk image:

```sh
ARCHS='arm64 x86_64' ./scripts/build-app.sh
./scripts/package-dmg.sh
```

The scripts support Xcode and standalone Command Line Tools. Integration tests use isolated named pasteboards and temporary SQLite databases. Coverage is enabled. Tests cover history limits, ordering, memory bounds, filtering, private clipboard markers, rich-content round-trips, shortcut persistence, paste eligibility, database reopening, deletion, and corruption handling. Accessibility event delivery still requires manual testing in destination apps.

For UI review, `open -n dist/Clipglass.app --args --demo` uses synthetic entries, does not capture clipboard changes, and does not open the real history database.

See [contributing](CONTRIBUTING.md) and [release instructions](docs/releases.md).
