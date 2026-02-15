import SwiftUI

struct NstProfileView: View {
    let severity: NeckShoulderSeverity
    let program: NeckShoulderProgram?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(severityColor)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: severityIcon)
                            .font(.appTitle3)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Nacken-Schulter Profil")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text(severity.displayName)
                        .font(.appHeadline)
                        .foregroundStyle(severityColor)
                }

                Spacer()

                if let program {
                    Text("Woche \(program.currentWeek)/\(program.durationWeeks)")
                        .font(.outfit(.medium, size: 11))
                        .foregroundStyle(severityColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(severityColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                }
            }

            // Description
            Text(severityDescription)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }

    var severityColor: Color {
        switch severity {
        case .mild: .painGreen
        case .moderate: .painAmber
        case .high: .painRed
        }
    }

    private var severityIcon: String {
        switch severity {
        case .mild: "checkmark.circle"
        case .moderate: "exclamationmark.circle"
        case .high: "exclamationmark.triangle"
        }
    }

    private var severityDescription: String {
        switch severity {
        case .mild:
            "Leichte Verspannung. Standard-Programm mit voller Belastungssteigerung."
        case .moderate:
            "Moderate Verspannung. Angepasstes Programm mit langsamerer Steigerung und haufigeren Mikro-Pausen."
        case .high:
            "Deutliche Verspannung. Sanfter Start mit verlangerten Phasen und reduzierter Intensitat."
        }
    }
}

// MARK: - Quick Card (for ProgramTab)

struct NstProfileQuickCard: View {
    let severity: NeckShoulderSeverity

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous)
                .fill(severityColor)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "figure.mind.and.body")
                        .font(.appBody)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Schweregrad")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Text(severity.displayName)
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.textPrimary)
            }

            Spacer()
        }
        .accentCardStyle(color: severityColor)
    }

    private var severityColor: Color {
        switch severity {
        case .mild: .painGreen
        case .moderate: .painAmber
        case .high: .painRed
        }
    }
}
