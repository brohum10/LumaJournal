import Foundation
import SwiftData

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

    init(text: String, extraction: JournalExtraction? = nil, now: Date = .now) {
        id = UUID()
        createdAt = now
        updatedAt = now
        self.text = text
        mood = extraction?.mood
        moodScore = extraction?.moodScore
        topics = extraction?.topics ?? []
        summary = extraction?.summary
    }
}
