import Foundation
import FoundationModels

@Generable(description: "A concise, structured analysis of a private journal entry")
struct JournalExtraction: Sendable {
    @Guide(description: "One lowercase mood word, such as calm, joyful, anxious, sad, frustrated, or neutral")
    var mood: String

    @Guide(description: "Mood valence from 1 (very difficult) to 5 (very positive)", .range(1...5))
    var moodScore: Int

    @Guide(description: "A compassionate one-sentence summary that introduces no new facts")
    var summary: String

    @Guide(description: "Two to five short topic labels", .maximumCount(5))
    var topics: [String]

    @Guide(description: "Concrete tasks explicitly stated or strongly implied by the writer", .maximumCount(6))
    var todos: [GeneratedTodo]

    @Guide(description: "Calendar-worthy events with a specific date or time", .maximumCount(4))
    var events: [GeneratedEvent]
}

@Generable
struct GeneratedTodo: Sendable, Identifiable {
    @Guide(description: "A short unique identifier")
    var id: String
    @Guide(description: "Short action-oriented title")
    var title: String
    @Guide(description: "ISO-8601 date and time if the journal states one, otherwise an empty string")
    var dueDateISO8601: String
}

@Generable
struct GeneratedEvent: Sendable, Identifiable {
    @Guide(description: "A short unique identifier")
    var id: String
    @Guide(description: "Short event title")
    var title: String
    @Guide(description: "ISO-8601 start date and time")
    var startDateISO8601: String
    @Guide(description: "Duration in minutes, defaulting to 60", .range(5...1440))
    var durationMinutes: Int
}

extension JournalExtraction {
    /// Treat model output as untrusted structured data before it reaches persistence or EventKit.
    func normalized() -> JournalExtraction {
        var seenTopics = Set<String>()
        var seenTodoIDs = Set<String>()
        var seenEventIDs = Set<String>()
        let cleanTopics = topics.compactMap { raw -> String? in
            let topic = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !topic.isEmpty, seenTopics.insert(topic.lowercased()).inserted else { return nil }
            return topic
        }.prefix(5)

        let cleanTodos = todos.prefix(6).enumerated().compactMap { index, todo -> GeneratedTodo? in
            let title = String(todo.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(160))
            guard !title.isEmpty else { return nil }
            let rawID = todo.id.trimmingCharacters(in: .whitespacesAndNewlines)
            var id = String((rawID.isEmpty ? "todo-\(index + 1)" : rawID).prefix(80))
            if !seenTodoIDs.insert(id).inserted {
                id = "\(id)-\(index + 1)"
                seenTodoIDs.insert(id)
            }
            return GeneratedTodo(
                id: id,
                title: title,
                dueDateISO8601: todo.dueDateISO8601.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        let cleanEvents = events.prefix(4).enumerated().compactMap { index, event -> GeneratedEvent? in
            let title = String(event.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(160))
            guard !title.isEmpty else { return nil }
            let rawID = event.id.trimmingCharacters(in: .whitespacesAndNewlines)
            var id = String((rawID.isEmpty ? "event-\(index + 1)" : rawID).prefix(80))
            if !seenEventIDs.insert(id).inserted {
                id = "\(id)-\(index + 1)"
                seenEventIDs.insert(id)
            }
            return GeneratedEvent(
                id: id,
                title: title,
                startDateISO8601: event.startDateISO8601.trimmingCharacters(in: .whitespacesAndNewlines),
                durationMinutes: min(max(event.durationMinutes, 5), 1_440)
            )
        }

        let cleanMood = String(mood.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().prefix(40))
        return JournalExtraction(
            mood: cleanMood.isEmpty ? "neutral" : cleanMood,
            moodScore: min(max(moodScore, 1), 5),
            summary: String(summary.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500)),
            topics: Array(cleanTopics),
            todos: cleanTodos,
            events: cleanEvents
        )
    }
}

enum ExtractionDateParser {
    static func date(from value: String) -> Date? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        if let date = standard.date(from: value) { return date }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value)
    }
}
