import SwiftUI

struct NstComplianceView: View {
    let compliance: NeckShoulderComplianceStats?
    let accentColor: Color

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(accentColor)
                Text("Wochenfortschritt")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
                if let compliance {
                    Text("Woche \(compliance.weekNumber)")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)
                }
            }

            if let compliance {
                // Overall percentage
                VStack(spacing: 6) {
                    Text("\(Int(compliance.overallPercent))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(overallColor(compliance.overallPercent))

                    ProgressView(value: min(compliance.overallPercent, 100), total: 100)
                        .tint(overallColor(compliance.overallPercent))

                    Text("Gesamtfortschritt")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.bottom, 4)

                // Breakdown rows
                VStack(spacing: 10) {
                    ComplianceRow(
                        icon: "figure.strengthtraining.traditional",
                        label: "Kraft",
                        completed: compliance.strengthSessionsCompleted,
                        target: compliance.strengthSessionsTarget,
                        accentColor: accentColor
                    )

                    ComplianceRow(
                        icon: "figure.flexibility",
                        label: "Mobilitat",
                        completed: compliance.mobilitySessionsCompleted,
                        target: compliance.mobilitySessionsTarget,
                        accentColor: accentColor
                    )

                    ComplianceRow(
                        icon: "timer",
                        label: "Mikro-Pausen",
                        completed: compliance.microPausesCompleted,
                        target: 0, // Micro-pauses are bonus, no target in overall
                        accentColor: accentColor,
                        isBonus: true
                    )
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(.gray300)
                    Text("Noch keine Sitzungen diese Woche")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.vertical, 12)
            }
        }
        .cardStyle()
    }

    private func overallColor(_ percent: Double) -> Color {
        if percent >= 66 { return .painGreen }
        if percent >= 33 { return .painAmber }
        return .painRed
    }
}

// MARK: - Compliance Row

private struct ComplianceRow: View {
    let icon: String
    let label: String
    let completed: Int
    let target: Int
    let accentColor: Color
    var isBonus: Bool = false

    private var fraction: Double {
        guard target > 0 else { return isBonus ? 1.0 : 0.0 }
        return min(Double(completed) / Double(target), 1.0)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.appCaption)
                .foregroundStyle(accentColor)
                .frame(width: 20)

            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(.textPrimary)
                .frame(width: 90, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.gray200)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(accentColor)
                        .frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)

            if isBonus {
                Text("\(completed)")
                    .font(.appCaptionBold)
                    .foregroundStyle(accentColor)
                    .frame(width: 40, alignment: .trailing)
            } else {
                Text("\(completed)/\(target)")
                    .font(.appCaptionBold)
                    .foregroundStyle(completed >= target ? .painGreen : .textSecondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
}
