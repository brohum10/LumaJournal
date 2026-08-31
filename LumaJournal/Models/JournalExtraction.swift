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

enum ExtractionDateParser {
    static func date(from value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: value)
    }
}
