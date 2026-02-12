import SwiftUI

struct NeckProfileView: View {
    let severity: NdiSeverityGrade
    let neckSubtype: NeckSubtype?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Severity badge
                Circle()
                    .fill(Color.severityColor(for: severity))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: severityIcon)
                            .font(.title3)
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("NDI-Schweregrad")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                    Text(severity.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.severityColor(for: severity))
                }

                Spacer()

                // Severity pill
                Text(severityLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.severityColor(for: severity))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.severityColor(for: severity).opacity(0.1))
                    .clipShape(Capsule())
            }

            // Subtype info
            if let subtype = neckSubtype, subtype == .neckRadiculopathy {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.painAmber)
                    Text("Radiculopathie — angepasstes Programm")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(10)
                .background(Color.painAmber.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Description
            Text(severityDescription)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var severityIcon: String {
        switch severity {
        case .LEICHT: return "checkmark.circle"
        case .MITTEL: return "exclamationmark.circle"
        case .SCHWER: return "exclamationmark.triangle"
        }
    }

    var severityLabel: String {
        switch severity {
        case .LEICHT: return "Mild"
        case .MITTEL: return "Moderat"
        case .SCHWER: return "Schwer"
        }
    }

    var severityDescription: String {
        switch severity {
        case .LEICHT:
            "Leichte Einschrankung. Standard-Ubungsprogression mit allen Intensitatsstufen."
        case .MITTEL:
            "Moderate Einschrankung. Angepasste Ubungen mit langsamerer Steigerung."
        case .SCHWER:
            "Deutliche Einschrankung. Sanfter Beginn mit verlangerten Phasen und reduzierter Belastung."
        }
    }
}
