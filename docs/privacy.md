# Privacy model

Luma follows data minimization: a feature receives private journal content only when that content is necessary for the user-requested operation.

| Capability | Data involved | Destination | Trigger |
|---|---|---|---|
| Journal persistence | entry text and extracted metadata | local SwiftData store | user taps Save |
| Analysis | current entry text | Apple's on-device system language model | user taps Analyze |
| Dictation | live microphone audio | on-device Speech recognizer | user taps Dictate |
| Reminder creation | reviewed title and optional date | EventKit reminder store | user taps Add |
| Event creation | reviewed title, date, and duration | EventKit calendar store | user taps Add |
| Insights | local entry metadata | memory only | user opens Insights |
| Export | one human-readable entry | system share sheet target chosen by user | user taps Export |

## Guarantees in this repository

- no HTTP client or remote API dependency
- no account, analytics, ad, tracking, telemetry, or crash-reporting SDK
- no automatic reminder or calendar writes
- on-device recognition is required; unsupported dictation fails closed
- analysis never blocks saving a plain journal entry
- generated output is reviewed and validated before capability use
- privacy manifest declares no tracking and no collected data types

## Platform-controlled behavior

SwiftData storage protection, device backups, Apple Intelligence availability, Speech recognition support, EventKit permissions, and the selected share destination are controlled by iOS and the user's settings. Luma describes those boundaries directly rather than claiming that data can never leave a device after the user explicitly exports or backs it up.
