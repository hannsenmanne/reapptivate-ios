import SwiftUI

struct ComplianceCalendarCard: View {
    let entries: [ProgressEntry]

    private let dayLabels = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var calendarDays: [CalendarDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find the Monday 4 weeks ago
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0
        guard let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let startDate = calendar.date(byAdding: .day, value: -21, to: thisMonday) else {
            return []
        }

        // Count entries per day using UTC date-only string to prevent timezone shifts
        var countByDate: [String: Int] = [:]
        for entry in entries {
            if let date = entry.completedAtDate {
                let key = date.dateOnlyString // Uses UTC timezone
                countByDate[key, default: 0] += 1
            }
        }

        // Build 28 days
        var days: [CalendarDay] = []
        for i in 0..<28 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            let key = date.dateOnlyString // Uses UTC timezone
            let count = countByDate[key] ?? 0
            let isFuture = date > today
            days.append(CalendarDay(date: date, count: count, isFuture: isFuture))
        }
        return days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.accent)
                Text("Trainingskalender")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            // Day labels
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays) { day in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(dayColor(for: day))
                        .frame(height: 28)
                        .overlay {
                            if day.count > 0 && !day.isFuture {
                                Text("\(day.count)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                }
            }

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: Color.textSecondary.opacity(0.08), label: "Kein Training")
                LegendItem(color: Color.accent.opacity(0.35), label: "1-2")
                LegendItem(color: Color.accent, label: "3+")
            }
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    private func dayColor(for day: CalendarDay) -> Color {
        if day.isFuture { return Color.textSecondary.opacity(0.04) }
        if day.count == 0 { return Color.textSecondary.opacity(0.08) }
        if day.count <= 2 { return Color.accent.opacity(0.35) }
        return Color.accent
    }
}

private struct CalendarDay: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
    let isFuture: Bool
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)
        }
    }
}
