import SwiftUI
import Charts

struct PainTrendChart: View {
    let painLevels: [StatsResponse.RecentPain]

    private var chartData: [PainTrendDataPoint] {
        painLevels.compactMap { entry in
            // Parse date-only string in UTC timezone to prevent shifts
            guard let date = Date.fromDateOnly(entry.date) else { return nil }
            return PainTrendDataPoint(date: date, pain: entry.avgPain)
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.accent)
                Text("Schmerzentwicklung")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if chartData.count >= 2 {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value("Schmerz", point.pain)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accent)

                    AreaMark(
                        x: .value("Datum", point.date),
                        y: .value("Schmerz", point.pain)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accent.opacity(0.3), Color.accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value("Schmerz", point.pain)
                    )
                    .foregroundStyle(Color.accent)
                    .symbolSize(24)
                }
                .chartYScale(domain: 0...10)
                .chartYAxis {
                    AxisMarks(values: [0, 3, 5, 10]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.textSecondary.opacity(0.2))
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.appCaption2)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.textSecondary.opacity(0.1))
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(.appCaption2)
                            .foregroundStyle(.textSecondary)
                    }
                }
                .frame(height: 200)
            } else {
                Text("Noch nicht genügend Daten für den Trend")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            }
        }
        .cardStyle()
    }

}

private struct PainTrendDataPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let pain: Double
}
