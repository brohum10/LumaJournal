import SwiftData
import SwiftUI

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var isComposing = false
    @State private var isShowingInsights = false
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var pendingDeletion: JournalEntry?

    private var filteredEntries: [JournalEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }
        return entries.filter { entry in
            entry.text.localizedCaseInsensitiveContains(query) ||
            entry.summary?.localizedCaseInsensitiveContains(query) == true ||
            entry.mood?.localizedCaseInsensitiveContains(query) == true ||
            entry.topics.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "A quiet place for your thoughts" : "No matching entries",
                        systemImage: searchText.isEmpty ? "book.closed" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Write or speak an entry. Apple Intelligence can organize it privately on your iPhone." : "Try another word or topic.")
                    )
                } else {
                    List(filteredEntries) { entry in
                        NavigationLink {
                            EntryDetailView(entry: entry)
                        } label: {
                            HStack(spacing: 14) {
                                MoodOrb(score: entry.moodScore)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(entry.summary ?? entry.text)
                                        .font(.headline)
                                        .lineLimit(2)
                                    HStack {
                                        Text(entry.createdAt, format: .dateTime.month(.abbreviated).day())
                                        if let mood = entry.mood { Text("• \(mood.capitalized)") }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { pendingDeletion = entry } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Luma")
            .searchable(text: $searchText, prompt: "Thoughts, moods, or topics")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { isShowingInsights = true } label: {
                        Label("Insights", systemImage: "chart.bar.xaxis")
                    }
                    .disabled(entries.isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { isComposing = true } label: { Label("New entry", systemImage: "square.and.pencil") }
                }
            }
            .sheet(isPresented: $isComposing) { EntryEditorView() }
            .sheet(isPresented: $isShowingInsights) {
                InsightsView(insights: .calculate(entries: entries))
            }
            .alert("Luma Journal", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "") }
            .confirmationDialog(
                "Delete this entry?",
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete entry", role: .destructive) {
                    if let entry = pendingDeletion { delete(entry) }
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("This removes the entry and its saved suggestions from this device.")
            }
        }
    }

    private func delete(_ entry: JournalEntry) {
        modelContext.delete(entry)
        do { try modelContext.save() }
        catch {
            modelContext.rollback()
            errorMessage = "This entry couldn’t be deleted: \(error.localizedDescription)"
        }
    }
}

struct EntryDetailView: View {
    let entry: JournalEntry
    @State private var alertMessage: String?
    private let eventWriter = EventKitWriter()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack { MoodOrb(score: entry.moodScore); Text(entry.mood?.capitalized ?? "Not analyzed").font(.title2.bold()) }
                if let summary = entry.summary { Text(summary).font(.title3).foregroundStyle(.secondary) }
                Text(entry.text).font(.body).textSelection(.enabled)
                if !entry.topics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(entry.topics, id: \.self) { Text($0).padding(.horizontal, 12).padding(.vertical, 7).background(.indigo.opacity(0.12), in: Capsule()) } }
                    }
                }
                if !entry.todos.isEmpty {
                    suggestionSection("Suggested reminders", systemImage: "checklist") {
                        ForEach(entry.todos) { todo in
                            actionRow(title: todo.title, icon: "circle") {
                                try await eventWriter.addReminder(
                                    title: todo.title,
                                    dueDate: ExtractionDateParser.date(from: todo.dueDateISO8601)
                                )
                                return "Reminder added."
                            }
                        }
                    }
                }
                if !entry.events.isEmpty {
                    suggestionSection("Suggested events", systemImage: "calendar") {
                        ForEach(entry.events) { event in
                            actionRow(title: event.title, icon: "calendar.badge.plus") {
                                guard let start = ExtractionDateParser.date(from: event.startDateISO8601) else {
                                    return "The event date needs clarification."
                                }
                                try await eventWriter.addEvent(
                                    title: event.title,
                                    startDate: start,
                                    durationMinutes: event.durationMinutes
                                )
                                return "Calendar event added."
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: entry.markdownExport) {
                    Label("Export entry", systemImage: "square.and.arrow.up")
                }
            }
        }
        .alert("Luma Journal", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) { Button("OK", role: .cancel) {} } message: { Text(alertMessage ?? "") }
    }

    private func suggestionSection<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage).font(.headline)
            content()
        }
        .padding()
        .background(.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }

    private func actionRow(
        title: String,
        icon: String,
        action: @escaping () async throws -> String
    ) -> some View {
        HStack {
            Label(title, systemImage: icon).lineLimit(2)
            Spacer()
            Button("Add") {
                Task {
                    do { alertMessage = try await action() }
                    catch { alertMessage = error.localizedDescription }
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
