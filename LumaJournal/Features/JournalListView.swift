import SwiftData
import SwiftUI

struct JournalListView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var isComposing = false
    @State private var searchText = ""

    private var filteredEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { entry in
            entry.text.localizedCaseInsensitiveContains(searchText) ||
            entry.topics.contains { $0.localizedCaseInsensitiveContains(searchText) }
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
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Luma")
            .searchable(text: $searchText, prompt: "Thoughts or topics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isComposing = true } label: { Label("New entry", systemImage: "square.and.pencil") }
                }
            }
            .sheet(isPresented: $isComposing) { EntryEditorView() }
        }
    }
}

struct EntryDetailView: View {
    let entry: JournalEntry
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
}
