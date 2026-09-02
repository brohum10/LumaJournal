import SwiftData
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var text = ""
    @State private var extraction: JournalExtraction?
    @State private var isAnalyzing = false
    @State private var analysisTask: Task<Void, Never>?
    @State private var alertMessage: String?
    @State private var transcriber = SpeechTranscriber()
    private let analyzer: any JournalAnalyzing = OnDeviceJournalAnalyzer()
    private let eventWriter = EventKitWriter()

    private var trimmedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

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
                        Text("\(text.count.formatted()) characters")
                        Spacer()
                        if text.count > 20_000 { Text("Shorten to analyze") }
                    }
                    .font(.caption)
                    .foregroundStyle(text.count > 20_000 ? .orange : .secondary)

                    HStack {
                        Button {
                            let existingText = trimmedText
                            Task {
                                await transcriber.toggle { transcript in
                                    text = existingText.isEmpty ? transcript : existingText + "\n\n" + transcript
                                }
                            }
                        } label: {
                            Label(transcriber.isRecording ? "Stop" : "Dictate", systemImage: transcriber.isRecording ? "stop.circle.fill" : "waveform")
                        }
                        .buttonStyle(.bordered)
                        .disabled(transcriber.isStarting)
                        Spacer()
                        Label("On device", systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary)
                    }

                    Button { analyze() } label: {
                        Label(extraction == nil ? "Find themes and actions" : "Analyze again", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedText.isEmpty || text.count > 20_000 || isAnalyzing)

                    if let extraction { ReviewCard(extraction: extraction, writer: eventWriter, alertMessage: $alertMessage) }
                }
                .padding()
            }
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedText.isEmpty || isAnalyzing)
                }
            }
            .overlay { if isAnalyzing { ProgressView("Finding themes…").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16)) } }
            .alert("Luma Journal", isPresented: Binding(get: { alertMessage != nil || transcriber.errorMessage != nil }, set: { if !$0 { alertMessage = nil; transcriber.errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(alertMessage ?? transcriber.errorMessage ?? "") }
            .onChange(of: text) { oldValue, newValue in
                if oldValue != newValue, extraction != nil { extraction = nil }
            }
            .onDisappear {
                analysisTask?.cancel()
                transcriber.stop()
            }
        }
    }

    private func analyze() {
        guard case .available = analyzer.availability() else {
            if case let .unavailable(reason) = analyzer.availability() { alertMessage = reason }
            return
        }
        let source = trimmedText
        isAnalyzing = true
        analysisTask?.cancel()
        analysisTask = Task {
            defer { isAnalyzing = false }
            do {
                let result = try await analyzer.analyze(source, now: .now)
                guard !Task.isCancelled, trimmedText == source else { return }
                extraction = result
            } catch is CancellationError {
                return
            } catch {
                alertMessage = "This entry couldn’t be analyzed: \(error.localizedDescription)"
            }
        }
    }

    private func save() {
        let entry = JournalEntry(text: trimmedText, extraction: extraction)
        modelContext.insert(entry)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            alertMessage = "This entry couldn’t be saved: \(error.localizedDescription)"
        }
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
