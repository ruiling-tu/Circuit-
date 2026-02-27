import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @Query(sort: \SelfNote.date, order: .reverse) private var notes: [SelfNote]

    @State private var showHelpfulOnly = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("History")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.75))

                    SummaryCard(sessions: sessions)

                    Toggle("Show only helpful sessions", isOn: $showHelpfulOnly)
                        .toggleStyle(.switch)
                        .padding(.horizontal, 8)

                    if !notes.isEmpty {
                        NotesSection(notes: notes)
                    }

                    VStack(spacing: 12) {
                        ForEach(filteredSessions) { session in
                            SessionCard(session: session)
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    private var filteredSessions: [Session] {
        if showHelpfulOnly {
            return sessions.filter { $0.helpedRating == 2 }
        }
        return sessions
    }
}

private struct SummaryCard: View {
    let sessions: [Session]

    var body: some View {
        let common = AnalyticsService.mostCommonState(from: sessions) ?? "-"
        let weekly = AnalyticsService.weeklyCount(from: sessions)
        let streak = AnalyticsService.streak(from: sessions)

        return VStack(alignment: .leading, spacing: 8) {
            Text("This week: \(weekly) resets")
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.8))
            Text("Most common: \(common)")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.6))
            Text("Streak: \(streak) days")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.6))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
        )
    }
}

private struct NotesSection: View {
    let notes: [SelfNote]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Self messages")
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.7))

            VStack(spacing: 12) {
                ForEach(notes) { note in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\"\(note.text)\"")
                            .font(.subheadline)
                            .foregroundStyle(Color.black.opacity(0.8))
                        HStack {
                            if note.isPinned {
                                Text("Pinned")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.black.opacity(0.55))
                            }
                            Text(note.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(Color.black.opacity(0.5))
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                    )
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

private struct SessionCard: View {
    let session: Session
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.state)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.8))

            Text(session.microAction)
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.6))

            if let helped = session.helpedRating {
                Text(helpedLabel(for: helped))
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.5))
            }

            if showDetails {
                Text("Loop: \(session.distortion) • \(session.reframe)")
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.5))
            }

            Button(showDetails ? "Hide details" : "Show details") {
                showDetails.toggle()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.black.opacity(0.55))

            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(Color.black.opacity(0.45))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
    }

    private func helpedLabel(for value: Int) -> String {
        switch value {
        case 2: return "Helped"
        case 1: return "Somewhat helped"
        default: return "Did not help"
        }
    }
}
