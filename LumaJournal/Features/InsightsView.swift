import SwiftUI

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    let insights: JournalInsights

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("A private snapshot of patterns in your journal. Calculated entirely on this device.")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        metric(title: "Entries", value: insights.entryCount.formatted(), icon: "book.pages")
                        metric(title: "Active days", value: insights.activeDayCount.formatted(), icon: "calendar")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Mood", systemImage: "waveform.path.ecg").font(.headline)
                        if let average = insights.averageMood {
                            Text(average.formatted(.number.precision(.fractionLength(1))) + " / 5")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            ProgressView(value: average, total: 5).tint(.indigo)
                            Text("Based on \(insights.analyzedCount) analyzed \(insights.analyzedCount == 1 ? "entry" : "entries").")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("Analyze an entry to begin seeing mood patterns.").foregroundStyle(.secondary)
                        }
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Recurring topics", systemImage: "tag").font(.headline)
                        if insights.topTopics.isEmpty {
                            Text("Topics appear after entries are analyzed.").foregroundStyle(.secondary)
                        } else {
                            ForEach(insights.topTopics) { topic in
                                HStack {
                                    Text(topic.topic.capitalized)
                                    Spacer()
                                    Text(topic.count.formatted()).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func metric(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.indigo)
            Text(value).font(.title.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private extension View {
    func cardStyle() -> some View {
        padding()
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }
}
