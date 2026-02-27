import SwiftUI
import SwiftData

struct PatternsView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Patterns")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.75))

                    InsightsCard(title: "Top feelings", items: AnalyticsService.topItems(from: sessions, key: \Session.state))
                    InsightsCard(title: "Top distortions", items: AnalyticsService.topItems(from: sessions, key: \Session.distortion))
                    InsightsCard(title: "Top reframes", items: AnalyticsService.topItems(from: sessions, key: \Session.reframe))

                    if let rate = AnalyticsService.completionRate(started: startedCount, completed: completedCount) {
                        StatCard(title: "Completion rate", value: "\(Int(rate * 100))%")
                    }

                    if let best = AnalyticsService.topHelpfulReframe(from: sessions) {
                        StatCard(title: "What helped most", value: "When \(best.state), try \(best.reframe)")
                    }

                    if let median = AnalyticsService.medianDuration(from: sessions) {
                        StatCard(title: "Median time", value: "\(Int(median))s")
                    }

                    if let p90 = AnalyticsService.percentileDuration(from: sessions, percentile: 90) {
                        StatCard(title: "90th percentile", value: "\(Int(p90))s")
                    }
                }
                .padding(24)
            }
        }
    }

    private var startedCount: Int {
        UserDefaults.standard.integer(forKey: "resetsStarted")
    }

    private var completedCount: Int {
        UserDefaults.standard.integer(forKey: "resetsCompleted")
    }
}

private struct InsightsCard: View {
    let title: String
    let items: [(String, Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.7))

            if items.isEmpty {
                Text("Not enough data yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.5))
            } else {
                ForEach(items, id: \..0) { item in
                    HStack {
                        Text(item.0)
                            .foregroundStyle(Color.black.opacity(0.8))
                        Spacer()
                        Text("\(item.1)")
                            .foregroundStyle(Color.black.opacity(0.5))
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.7))
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.6))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}
