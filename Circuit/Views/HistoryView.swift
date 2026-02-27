import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @Query(sort: \SelfNote.date, order: .reverse) private var notes: [SelfNote]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("History")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.75))

                    SummaryCard(sessions: sessions)

                    if !notes.isEmpty {
                        NotesSection(notes: notes)
                    }

                    VStack(spacing: 12) {
                        ForEach(sessions) { session in
                            SessionRow(session: session)
                        }
                    }
                }
                .padding(24)
            }
        }
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
                        Text(note.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color.black.opacity(0.5))
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

private struct SessionRow: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.state)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.8))

            Text("\(session.distortion) • \(session.microAction)")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.6))

            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(Color.black.opacity(0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
    }
}
