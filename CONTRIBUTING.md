# Contributing

Open an issue to discuss larger changes. For fixes, submit a focused pull request with the problem, changed behavior, and checks you ran.

Use Swift 6.2+ and macOS 26+. Run `./scripts/test.sh` and `./scripts/build-app.sh` before submitting. Keep platform-independent logic in ClipboardCore, macOS integrations in ClipboardMac, and UI in Clipglass. Test new behavior using named pasteboards and temporary databases, never the developer's real clipboard or history.

Include before/after screenshots with synthetic content for UI changes. Check keyboard navigation, light/dark appearance, and Reduce Motion. Do not include clipboard data, credentials, signing certificates, or private screenshots in issues or commits.

By contributing, you agree to license your contributions under the project's MIT license.
