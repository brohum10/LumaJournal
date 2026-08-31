import SwiftData
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var text = ""
    @State private var extraction: JournalExtraction?
    @State private var isAnalyzing = false
    @State private var alertMessage: String?
    @State private var transcriber = SpeechTranscriber()
    private let analyzer: any JournalAnalyzing = OnDeviceJournalAnalyzer()
    private let eventWriter = EventKitWriter()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("What’s on your mind?").font(.largeTitle.bold())
                    TextEditor(text: $text)
                        .frame(minHeight: 220)
                        .padding(12)
                        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityLabel("Journal entry")

                    HStack {
                        Button {
                            Task { await transcriber.toggle { text = $0 } }
                        } label: {
                            Label(transcriber.isRecording ? "Stop" : "Dictate", systemImage: transcriber.isRecording ? "stop.circle.fill" : "waveform")
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Label("On device", systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary)
                    }

                    if let extraction { ReviewCard(extraction: extraction, writer: eventWriter, alertMessage: $alertMessage) }
                }
                .padding()
            }
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(extraction == nil ? "Analyze" : "Save") {
                        extraction == nil ? analyze() : save()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)
                }
            }
            .overlay { if isAnalyzing { ProgressView("Finding themes…").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16)) } }
            .alert("Luma Journal", isPresented: Binding(get: { alertMessage != nil || transcriber.errorMessage != nil }, set: { if !$0 { alertMessage = nil; transcriber.errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(alertMessage ?? transcriber.errorMessage ?? "") }
        }
    }

    private func analyze() {
        guard case .available = analyzer.availability() else {
            if case let .unavailable(reason) = analyzer.availability() { alertMessage = reason }
            return
        }
        isAnalyzing = true
        Task {
            do { extraction = try await analyzer.analyze(text, now: .now) }
            catch { alertMessage = "This entry couldn’t be analyzed: \(error.localizedDescription)" }
            isAnalyzing = false
        }
    }

    private func save() {
        modelContext.insert(JournalEntry(text: text, extraction: extraction))
        dismiss()
    }
}

private struct ReviewCard: View {
    let extraction: JournalExtraction
    let writer: EventKitWriter
    @Binding var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Ready for your review", systemImage: "sparkles").font(.headline)
            Text(extraction.summary).foregroundStyle(.secondary)
            HStack { Text(extraction.mood.capitalized).bold(); Text("Mood \(extraction.moodScore)/5").foregroundStyle(.secondary) }
            if !extraction.topics.isEmpty { Text(extraction.topics.joined(separator: "  •  ")).font(.caption).foregroundStyle(.indigo) }
            ForEach(extraction.todos) { todo in
                actionRow(title: todo.title, icon: "checklist") {
                    try await writer.addReminder(title: todo.title, dueDate: ExtractionDateParser.date(from: todo.dueDateISO8601))
                    return "Reminder added."
                }
            }
            ForEach(extraction.events) { event in
                actionRow(title: event.title, icon: "calendar") {
                    guard let start = ExtractionDateParser.date(from: event.startDateISO8601) else { return "The event date needs clarification." }
                    try await writer.addEvent(title: event.title, startDate: start, durationMinutes: event.durationMinutes)
                    return "Calendar event added."
                }
            }
        }
        .padding()
        .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    private func actionRow(title: String, icon: String, action: @escaping () async throws -> String) -> some View {
        HStack { Label(title, systemImage: icon).lineLimit(2); Spacer(); Button("Add") { Task { do { alertMessage = try await action() } catch { alertMessage = error.localizedDescription } } }.buttonStyle(.bordered) }
    }
}
