import XCTest
@testable import LumaJournal

@MainActor
final class ExtractionDateParserTests: XCTestCase {
    func testParsesISO8601Date() {
        XCTAssertNotNil(ExtractionDateParser.date(from: "2026-09-01T14:30:00-04:00"))
    }

    func testRejectsEmptyAndMalformedDates() {
        XCTAssertNil(ExtractionDateParser.date(from: ""))
        XCTAssertNil(ExtractionDateParser.date(from: "next Tuesday maybe"))
    }

    func testParsesFractionalSecondsAndWhitespace() {
        XCTAssertNotNil(ExtractionDateParser.date(from: " 2026-09-01T18:30:00.125Z "))
    }

    func testNormalizationBoundsAndCleansModelOutput() {
        let extraction = JournalExtraction(
            mood: "  JOYFUL ",
            moodScore: 9,
            summary: "  A grounded day.  ",
            topics: ["Work", " work ", "", "Friends"],
            todos: [
                GeneratedTodo(id: "", title: "  Send update  ", dueDateISO8601: "  "),
                GeneratedTodo(id: "skip", title: "   ", dueDateISO8601: "")
            ],
            events: [
                GeneratedEvent(id: "", title: " Dinner ", startDateISO8601: " 2026-09-01T19:00:00-04:00 ", durationMinutes: 2)
            ]
        ).normalized()

        XCTAssertEqual("joyful", extraction.mood)
        XCTAssertEqual(5, extraction.moodScore)
        XCTAssertEqual("A grounded day.", extraction.summary)
        XCTAssertEqual(["Work", "Friends"], extraction.topics)
        XCTAssertEqual("todo-1", extraction.todos.first?.id)
        XCTAssertEqual("Send update", extraction.todos.first?.title)
        XCTAssertEqual(5, extraction.events.first?.durationMinutes)
    }

    func testEntryRetainsSuggestionsAndExportsReadableMarkdown() {
        let extraction = JournalExtraction(
            mood: "calm",
            moodScore: 4,
            summary: "A productive afternoon.",
            topics: ["work"],
            todos: [GeneratedTodo(id: "t1", title: "Send update", dueDateISO8601: "")],
            events: [GeneratedEvent(id: "e1", title: "Team dinner", startDateISO8601: "2026-09-01T19:00:00-04:00", durationMinutes: 60)]
        )
        let entry = JournalEntry(text: "Finished the prototype.", extraction: extraction, now: Date(timeIntervalSince1970: 0))

        XCTAssertEqual("Send update", entry.todos.first?.title)
        XCTAssertEqual("Team dinner", entry.events.first?.title)
        XCTAssertTrue(entry.markdownExport.contains("Finished the prototype."))
        XCTAssertTrue(entry.markdownExport.contains("- [ ] Send update"))
    }

    func testInsightsAggregateMoodTopicsAndActiveDays() {
        let first = JournalEntry(
            text: "First",
            extraction: JournalExtraction(mood: "calm", moodScore: 4, summary: "", topics: ["Work", "Health"], todos: [], events: []),
            now: Date(timeIntervalSince1970: 0)
        )
        let second = JournalEntry(
            text: "Second",
            extraction: JournalExtraction(mood: "joyful", moodScore: 2, summary: "", topics: ["work"], todos: [], events: []),
            now: Date(timeIntervalSince1970: 86_400)
        )
        let insights = JournalInsights.calculate(entries: [first, second], calendar: Calendar(identifier: .gregorian))

        XCTAssertEqual(2, insights.entryCount)
        XCTAssertEqual(3.0, insights.averageMood)
        XCTAssertEqual(2, insights.activeDayCount)
        XCTAssertEqual(TopicFrequency(topic: "Work", count: 2), insights.topTopics.first)
    }
}
