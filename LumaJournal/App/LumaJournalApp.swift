import SwiftUI
import SwiftData

@main
struct LumaJournalApp: App {
    var body: some Scene {
        WindowGroup {
            JournalListView()
                .tint(.indigo)
        }
        .modelContainer(for: JournalEntry.self)
    }
}
