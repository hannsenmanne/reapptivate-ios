import SwiftUI

struct WorkTimerHistoryView: View {
    @Bindable var viewModel: WorkTimerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading && viewModel.weekHistory.isEmpty {
                        loadingSection
                    } else if viewModel.weekHistory.isEmpty {
                        emptySection
                    } else {
                        barChartSection
                        statsRow
                        dayDetailList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color.appBg)
            .navigationTitle("Wochenverlauf")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button("Schlie\u{00DF}en") {
                    dismiss()
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(Color.appBg)
            }
        }
        .presentationDetents([.large])
        .task {
            await viewModel.loadHistory()
            isLoading = false
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            ProgressView("Verlauf laden...")
                .font(.appSubheadline)
            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty

    private var emptySection: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            Image(systemName: "chart.bar")
                .font(.system(size: 36))
                .foregroundStyle(.textSecondary)
                .accessibilityHidden(true)
            Text("Noch keine Daten vorhanden")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
            Text("Starten Sie Ihren Arbeits-Timer, um Ihren Wochenverlauf zu sehen.")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bar Chart

    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Letzte 7 Tage")
                .font(.appSubheadlineSemibold)
                .foregroundStyle(.textPrimary)

            GeometryReader { geometry in
                let barSpacing: CGFloat = 8
                let barCount = CGFloat(sortedByDateAsc.count)
                let totalSpacing = barSpacing * max(0, barCount - 1)
                let barWidth = max(20, (geometry.size.width - totalSpacing) / max(1, barCount))

                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(sortedByDateAsc, id: \.date) { day in
                        BarColumn(day: day, barWidth: barWidth, maxHeight: 120)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 160)
        }
        .cardStyle()
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatPill(
                label: "\u{00D8} Adh\u{00E4}renz",
                value: "\(Int(viewModel.weeklyAdherence))%"
            )
            StatPill(
                label: "Serie",
                value: "\(viewModel.currentStreak) Tag\(viewModel.currentStreak == 1 ? "" : "e")"
            )
            StatPill(
                label: "Pausen",
                value: "\(totalBreaksCompleted)"
            )
        }
    }

    // MARK: - Day Detail List

    private var dayDetailList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.appSubheadlineSemibold)
                .foregroundStyle(.textPrimary)

            ForEach(sortedByDateDesc, id: \.date) { day in
                DayDetailRow(day: day)
            }
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private var sortedByDateAsc: [WorkTimerDaySummary] {
        viewModel.weekHistory.sorted { $0.date < $1.date }
    }

    private var sortedByDateDesc: [WorkTimerDaySummary] {
        viewModel.weekHistory.sorted { $0.date > $1.date }
    }

    private var totalBreaksCompleted: Int {
        viewModel.weekHistory.reduce(0) { $0 + $1.breaksCompleted }
    }
}

// MARK: - Bar Column

private struct BarColumn: View {
    let day: WorkTimerDaySummary
    let barWidth: CGFloat
    let maxHeight: CGFloat

    private var barColor: Color {
        let pct = day.adherencePercent
        if pct >= 70 { return .painGreen }
        if pct >= 40 { return .painAmber }
        return .painRed
    }

    private var barHeight: CGFloat {
        let fraction = day.adherencePercent / 100.0
        return max(4, CGFloat(fraction) * maxHeight)
    }

    private var dayLabel: String {
        guard let date = DateFormatters.dateOnly.date(from: day.date) else {
            return "?"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"
        let label = formatter.string(from: date)
        // EE gives "Mo.", "Di." etc. — strip the trailing period
        return label.replacingOccurrences(of: ".", with: "")
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(day.adherencePercent))%")
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(barColor)
                .frame(width: barWidth, height: barHeight)

            Text(dayLabel)
                .font(.appCaptionMedium)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dayLabel): \(Int(day.adherencePercent)) Prozent Adh\u{00E4}renz")
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
            Text(value)
                .font(.appSubheadlineSemibold)
                .foregroundStyle(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous)
                .stroke(Color.gray200, lineWidth: 1)
        )
    }
}

// MARK: - Day Detail Row

private struct DayDetailRow: View {
    let day: WorkTimerDaySummary

    private var formattedDate: String {
        guard let date = DateFormatters.dateOnly.date(from: day.date) else {
            return day.date
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE, d. MMM"
        return formatter.string(from: date)
    }

    private var adherenceColor: Color {
        let pct = day.adherencePercent
        if pct >= 70 { return .painGreen }
        if pct >= 40 { return .painAmber }
        return .painRed
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                Text("\(day.breaksCompleted) / \(day.breaksOffered) Pausen")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            Text("\(Int(day.adherencePercent))%")
                .font(.appSubheadlineSemibold)
                .foregroundStyle(adherenceColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(adherenceColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
        }
        .padding(.vertical, 4)
    }
}
