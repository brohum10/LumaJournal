import EventKit
import Foundation

actor EventKitWriter {
    private let store = EKEventStore()

    func addReminder(title: String, dueDate: Date?) async throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EventKitError.invalidSuggestion
        }
        guard try await store.requestFullAccessToReminders() else { throw EventKitError.accessDenied }
        guard let calendar = store.defaultCalendarForNewReminders() else { throw EventKitError.noCalendar }
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = calendar
        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .timeZone], from: dueDate
            )
        }
        try store.save(reminder, commit: true)
    }

    func addEvent(title: String, startDate: Date, durationMinutes: Int) async throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (5...1_440).contains(durationMinutes) else { throw EventKitError.invalidSuggestion }
        guard try await store.requestWriteOnlyAccessToEvents() else { throw EventKitError.accessDenied }
        guard let calendar = store.defaultCalendarForNewEvents else { throw EventKitError.noCalendar }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        event.calendar = calendar
        try store.save(event, span: .thisEvent, commit: true)
    }
}

private enum EventKitError: LocalizedError {
    case accessDenied
    case noCalendar
    case invalidSuggestion

    var errorDescription: String? {
        switch self {
        case .accessDenied: "Access was not granted. You can change this in Settings."
        case .noCalendar: "No writable calendar is available."
        case .invalidSuggestion: "This suggestion is incomplete and can’t be added."
        }
    }
}
