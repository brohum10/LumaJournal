import Foundation
import FoundationModels

enum AnalyzerAvailability: Equatable {
    case available
    case unavailable(String)
}

protocol JournalAnalyzing: Sendable {
    func availability() -> AnalyzerAvailability
    func analyze(_ text: String, now: Date) async throws -> JournalExtraction
}

struct OnDeviceJournalAnalyzer: JournalAnalyzing {
    func availability() -> AnalyzerAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailable("This device does not support Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable("Enable Apple Intelligence in Settings to analyze entries.")
        case .unavailable(.modelNotReady):
            return .unavailable("The on-device model is still preparing. Try again shortly.")
        case .unavailable:
            return .unavailable("The on-device model is currently unavailable.")
        }
    }

    func analyze(_ text: String, now: Date) async throws -> JournalExtraction {
        let session = LanguageModelSession(instructions: """
            Analyze only the supplied journal entry. Never diagnose mental health conditions.
            Do not invent people, tasks, dates, or events. Prefer an empty list when uncertain.
            Keep private content concise and factual. Dates must include a time zone.
            """)
        let currentDate = ISO8601DateFormatter().string(from: now)
        let response = try await session.respond(
            to: "Current date: \(currentDate)\n\nJournal entry:\n\(text)",
            generating: JournalExtraction.self
        )
        return response.content
    }
}
