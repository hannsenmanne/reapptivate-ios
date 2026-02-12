import SwiftUI

struct NeckResultView: View {
    let result: NeckScreeningResult
    let onContinue: () -> Void

    var severity: NdiSeverityGrade {
        NdiSeverityGrade.from(ndiScore: result.ndiScore)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score display
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.severityColor(for: severity))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Text("\(result.ndiScore)")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }

                    Text("NDI-Score: \(result.ndiScore)/50")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.textPrimary)

                    Text(severity.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.severityColor(for: severity))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.severityColor(for: severity).opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.top, 32)

                // Severity description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ihre Einstufung")
                        .font(.headline)
                        .foregroundStyle(.textPrimary)

                    Text(severityDescription)
                        .font(.body)
                        .foregroundStyle(.textSecondary)

                    Text(result.ndiCategory)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.textPrimary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Subtype result
                if result.subtypeResult == .neckRadiculopathy {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.painAmber)
                        Text("Radiculopathie erkannt. Ihr Ubungsprogramm ist entsprechend angepasst.")
                            .font(.subheadline)
                            .foregroundStyle(.textPrimary)
                    }
                    .padding(16)
                    .background(Color.painAmber.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text("Weiter zum Dashboard")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
            }
            .padding(24)
        }
        .background(Color.appBg)
    }

    var severityDescription: String {
        switch severity {
        case .LEICHT:
            "Leichte Einschrankung. Ihr Programm folgt der Standard-Ubungsprogression mit allen Intensitatsstufen."
        case .MITTEL:
            "Moderate Einschrankung. Ihr Programm enthalt angepasste Ubungen mit langsamerer Steigerung."
        case .SCHWER:
            "Deutliche Einschrankung. Ihr Programm beginnt sanft mit verlangerten Phasen und reduzierter Belastung."
        }
    }
}
