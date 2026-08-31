# Luma Journal

Luma Journal is a privacy-first iPhone journal that turns a typed or dictated note into a mood, topics, and actionable suggestions using Apple Intelligence on device.

## Highlights

- Structured generation with Apple's `FoundationModels` framework and `@Generable`
- Dictation with on-device speech recognition when the selected locale supports it
- Review-before-writing flow for Reminders and Calendar
- Local persistence with SwiftData; no analytics, accounts, or network layer
- Accessible SwiftUI interface, dark mode, search, and clear model-availability states
- Unit-tested date parsing and extraction mapping

## Requirements

- Xcode 26+
- iOS 26+
- A physical Apple Intelligence-capable iPhone with Apple Intelligence enabled for model features

## Run

1. Open `LumaJournal.xcodeproj`.
2. Select your development team for the `LumaJournal` target.
3. Run on a compatible iPhone. The simulator can exercise the UI and persistence but may report the system model as unavailable.

The app asks for microphone and speech permissions only when dictation starts. It asks for Reminders or Calendar access only after the user explicitly chooses to add an extracted item.

## Privacy architecture

Journal text is stored locally in SwiftData. Extraction is performed by `SystemLanguageModel.default` through `LanguageModelSession`; the app contains no HTTP client, remote API, analytics SDK, or account system. Suggested actions are displayed for confirmation before EventKit receives anything.

Speech recognition is configured with `requiresOnDeviceRecognition = true`. If on-device recognition is not supported for the active locale/device, dictation fails closed with a readable message rather than uploading audio.

## Project structure

- `App/` — app entry point and dependency container
- `Models/` — SwiftData and generated extraction types
- `Services/` — Foundation Models, speech, and EventKit boundaries
- `Features/` — journal list, editor, and review UI
- `DesignSystem/` — reusable visual components
- `LumaJournalTests/` — deterministic unit tests

## Design decisions

- A fresh model session per extraction avoids carrying one journal entry into another session context.
- Generated dates are ISO-8601 strings and parsed defensively; invalid dates remain visible as unscheduled suggestions.
- EventKit writes are individually initiated by the user and never run automatically.
- The protocol-backed analyzer keeps views testable and supports a preview implementation without invoking the model.

## License

MIT
