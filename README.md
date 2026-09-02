# Luma Journal

Luma Journal is a privacy-first iPhone journal that turns a typed or dictated note into a mood, topics, and actionable suggestions using Apple Intelligence on device. Journaling remains fully usable when the model is unavailable; analysis is an optional enhancement, never a gate in front of saving.

## Highlights

- Structured generation with Apple's `FoundationModels` framework and `@Generable`
- Dictation with on-device speech recognition when the selected locale supports it
- Review-before-writing flow for Reminders and Calendar
- Local persistence with SwiftData; no analytics, accounts, or network layer
- Persisted suggestions that can be revisited after saving
- Private insights for average mood, active days, and recurring topics
- Explicit Markdown export through the system share sheet
- Accessible SwiftUI interface, dark mode, broader search, and clear model-availability states
- Validation and normalization at the model boundary before generated data reaches storage or EventKit
- Unit-tested date parsing, extraction normalization, persistence mapping, export, and insight aggregation

## Requirements

- Xcode 26+
- iOS 26+
- A physical Apple Intelligence-capable iPhone with Apple Intelligence enabled for model features

## Run

1. Open `LumaJournal.xcodeproj`.
2. Select your development team for the `LumaJournal` target.
3. Run on a compatible iPhone. The simulator can exercise the UI and persistence but may report the system model as unavailable.

The app asks for microphone and speech permissions only when dictation starts. It asks for Reminders or Calendar access only after the user explicitly chooses to add an extracted item.

No Apple Intelligence support is required to write, search, read, delete, or export entries. The simulator is therefore useful for the complete non-generative workflow.

## Privacy architecture

Journal text is stored locally in SwiftData. Extraction is performed by `SystemLanguageModel.default` through `LanguageModelSession`; the app contains no HTTP client, remote API, analytics SDK, or account system. Suggested actions are displayed for confirmation before EventKit receives anything.

Speech recognition is configured with `requiresOnDeviceRecognition = true`. If on-device recognition is not supported for the active locale/device, dictation fails closed with a readable message rather than uploading audio.

Generated structures are treated as untrusted input: whitespace is cleaned, topic duplicates are removed, collection sizes and numeric ranges are bounded, blank actions are discarded, and dates are parsed defensively. A checked-in privacy manifest declares that the app performs no tracking or data collection.

## Project structure

- `App/` — app entry point and dependency container
- `Models/` — SwiftData and generated extraction types
- `Services/` — Foundation Models, speech, and EventKit boundaries
- `Features/` — journal list, editor, and review UI
- `DesignSystem/` — reusable visual components
- `LumaJournalTests/` — deterministic unit tests

See [Architecture](docs/architecture.md) for the data flow and model boundary, and [Privacy model](docs/privacy.md) for a capability-by-capability data inventory.

## Design decisions

- A fresh model session per extraction avoids carrying one journal entry into another session context.
- Saving is independent from analysis so model availability never blocks the core journal.
- Generated dates are ISO-8601 strings and parsed defensively; invalid dates remain visible as unscheduled suggestions.
- EventKit writes are individually initiated by the user and never run automatically.
- Reminders and events remain suggestions after save, letting users act later without running the model again.
- Editing text invalidates the visible extraction so stale analysis cannot be accidentally saved with changed prose.
- The protocol-backed analyzer keeps views testable and supports a preview implementation without invoking the model.

## Test and build

```bash
xcodebuild test \
  -project LumaJournal.xcodeproj \
  -scheme LumaJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO
```

GitHub Actions runs the same simulator suite on every pull request and preserves the Xcode result bundle when a failure needs investigation.

## Scope

Luma deliberately has no cloud sync, account, social feed, remote model fallback, diagnosis, or automated EventKit writes. Data backup follows the user's normal device backup configuration. Export happens only after the user opens the system share sheet.

## License

MIT
