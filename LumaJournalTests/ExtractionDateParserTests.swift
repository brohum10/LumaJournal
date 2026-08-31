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
}
