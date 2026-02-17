import SwiftUI

struct TensionProfileView: View {
    let severity: TsiSeverityGrade

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Severity badge
                Circle()
                    .fill(Color.severityColor(for: severity))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: severityIcon)
                            .font(.appTitle3)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("TSI-Schweregrad")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text(severity.displayName)
                        .font(.appHeadline)
                        .foregroundStyle(Color.severityColor(for: severity))
                }

                Spacer()

                // Severity pill
                Text(severity.displayName)
                    .font(.outfit(.medium, size: 11))
                    .foregroundStyle(Color.severityColor(for: severity))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.severityColor(for: severity).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
            }

            // Description
            Text(severityDescription)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }

    var severityIcon: String {
        switch severity {
        case .LEICHT: return "checkmark.circle"
        case .MITTEL: return "exclamationmark.circle"
        case .SCHWER: return "exclamationmark.triangle"
        }
    }

    var severityDescription: String {
        switch severity {
        case .LEICHT:
            "Leichte Verspannung. Standard-Übungsprogression mit allen Intensitätsstufen."
        case .MITTEL:
            "Moderate Verspannung. Angepasste Übungen mit langsamerer Steigerung."
        case .SCHWER:
            "Deutliche Verspannung. Sanfter Beginn mit verlängerten Phasen und reduzierter Belastung."
        }
    }
}
