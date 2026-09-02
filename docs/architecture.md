# Architecture

Luma Journal is intentionally a small, native application with explicit boundaries around every sensitive capability.

```text
typed text ───────────────┐
                         ├── EntryEditorView ─── SwiftData ─── journal list/detail
on-device speech ────────┘          │                              │
                                    │ explicit Analyze             ├── local insights
                                    ▼                              └── explicit export
                         JournalAnalyzing protocol
                                    │
                                    ▼
                       Foundation Models session
                                    │
                                    ▼
                     normalize + validate extraction
                                    │
                      review UI ────┴──── persisted suggestions
                           │
                  explicit Add button only
                           ▼
                    EventKitWriter actor
```

## Persistence

`JournalEntry` is the SwiftData aggregate. It stores prose, timestamps, mood metadata, topics, and encoded value-type snapshots of reminder/event suggestions. Encoding suggestions as stable `Codable` records decouples saved entries from the framework-generated model types and keeps them available after the generation session ends.

All entry mutations call `ModelContext.save()` explicitly so persistence failures remain visible rather than dismissing the editor optimistically.

## Generative boundary

`JournalAnalyzing` keeps Foundation Models behind a narrow async protocol. `OnDeviceJournalAnalyzer` creates a fresh `LanguageModelSession` for each entry, supplies the current date explicitly, requests a typed `@Generable` response, and normalizes that response before returning it.

Normalization is deterministic and enforces the application's assumptions: bounded mood scores and durations, maximum collection sizes, trimmed titles, case-insensitive topic deduplication, fallback IDs, and discarded blank actions. EventKit performs a final validation before writing.

## Availability and cancellation

Plain entries can always be saved. The analyzer maps system-model availability into actionable UI messages. Analysis tasks are cancellable, are cancelled when the editor disappears, and only publish results if the source text is unchanged. Dictation removes its audio tap on every exit path, including partial startup failures.

## Derived insights

`JournalInsights` is a deterministic local projection over existing entries. It calculates counts, unique active days, analyzed-entry mood average, and topic frequency. It has no persistence or network side effects, so its behavior can be unit tested independently from the UI.
