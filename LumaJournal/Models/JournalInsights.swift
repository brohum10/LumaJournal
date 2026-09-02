import Foundation

struct TopicFrequency: Identifiable, Equatable {
    let topic: String
    let count: Int
    var id: String { topic.lowercased() }
}

struct JournalInsights: Equatable {
    let entryCount: Int
    let analyzedCount: Int
    let averageMood: Double?
    let topTopics: [TopicFrequency]
    let activeDayCount: Int

    static func calculate(entries: [JournalEntry], calendar: Calendar = .current) -> JournalInsights {
        let scores = entries.compactMap(\.moodScore)
        let average = scores.isEmpty ? nil : Double(scores.reduce(0, +)) / Double(scores.count)
        var topicCounts: [String: (display: String, count: Int)] = [:]
        for topic in entries.flatMap(\.topics) {
            let key = topic.lowercased()
            topicCounts[key] = (topicCounts[key]?.display ?? topic, (topicCounts[key]?.count ?? 0) + 1)
        }
        let topTopics = topicCounts.values
            .sorted { $0.count == $1.count ? $0.display < $1.display : $0.count > $1.count }
            .prefix(5)
            .map { TopicFrequency(topic: $0.display, count: $0.count) }
        let activeDays = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        return JournalInsights(
            entryCount: entries.count,
            analyzedCount: scores.count,
            averageMood: average,
            topTopics: topTopics,
            activeDayCount: activeDays.count
        )
    }
}
