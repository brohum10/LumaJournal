import Foundation
import SwiftData

struct SavedTodo: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let dueDateISO8601: String
}

struct SavedEvent: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let startDateISO8601: String
    let durationMinutes: Int
}

@Model
final class JournalEntry {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var text: String
    var mood: String?
    var moodScore: Int?
    var topics: [String]
    var summary: String?
    var todosData: Data?
    var eventsData: Data?

    init(text: String, extraction: JournalExtraction? = nil, now: Date = .now) {
        let extraction = extraction?.normalized()
        id = UUID()
        createdAt = now
        updatedAt = now
        self.text = text
        mood = extraction?.mood
        moodScore = extraction?.moodScore
        topics = extraction?.topics ?? []
        summary = extraction?.summary
        todosData = extraction.map { extraction in
            try? JSONEncoder().encode(extraction.todos.map {
                SavedTodo(id: $0.id, title: $0.title, dueDateISO8601: $0.dueDateISO8601)
            })
        } ?? nil
        eventsData = extraction.map { extraction in
            try? JSONEncoder().encode(extraction.events.map {
                SavedEvent(
                    id: $0.id,
                    title: $0.title,
                    startDateISO8601: $0.startDateISO8601,
                    durationMinutes: $0.durationMinutes
                )
            })
        } ?? nil
    }

    var todos: [SavedTodo] { decode([SavedTodo].self, from: todosData) ?? [] }
    var events: [SavedEvent] { decode([SavedEvent].self, from: eventsData) ?? [] }

    var markdownExport: String {
        var sections = [
            "# Journal entry — \(createdAt.formatted(date: .long, time: .shortened))",
            text,
        ]
        if let summary, !summary.isEmpty { sections.append("## Reflection\n\(summary)") }
        if let mood { sections.append("**Mood:** \(mood.capitalized)\(moodScore.map { " (\($0)/5)" } ?? "")") }
        if !topics.isEmpty { sections.append("**Topics:** \(topics.joined(separator: ", "))") }
        if !todos.isEmpty { sections.append("## Suggested reminders\n" + todos.map { "- [ ] \($0.title)" }.joined(separator: "\n")) }
        if !events.isEmpty { sections.append("## Suggested events\n" + events.map { "- \($0.title)" }.joined(separator: "\n")) }
        return sections.joined(separator: "\n\n")
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from data: Data?) -> Value? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
