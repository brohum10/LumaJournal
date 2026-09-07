# Contributing to Luma Journal

Thanks for helping improve Luma Journal. Changes should preserve the app's privacy-first, local-first design and keep journaling usable when Apple Intelligence is unavailable.

## Development setup

1. Use Xcode 26 or newer.
2. Open `LumaJournal.xcodeproj`.
3. Select the `LumaJournal` scheme and an iOS 26 simulator.
4. Run the test target before opening a pull request.

Command-line verification mirrors CI:

```bash
plutil -lint LumaJournal/Info.plist LumaJournal/PrivacyInfo.xcprivacy
xcodebuild test -project LumaJournal.xcodeproj -scheme LumaJournal -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO
```

## Design expectations

- Keep journal content on device; do not introduce analytics, accounts, or remote model calls.
- Treat generated analysis as optional, validated input—not as a prerequisite for saving.
- Require an explicit review step before writing to Reminders or Calendar.
- Add deterministic tests for parsing, normalization, persistence mapping, and insights logic.
- Document any new permission or data flow in `docs/privacy.md`.

Pull requests should explain the user-visible behavior, privacy impact, tests performed, and any simulator-versus-device limitations.
