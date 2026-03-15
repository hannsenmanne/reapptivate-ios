import SwiftUI

struct InsightsTab: View {
    @Environment(AppState.self) private var appState
    let viewModel: DashboardViewModel?
    let phaseVM: PhaseViewModel?

    var body: some View {
        if appState.isLbp, let subtype = appState.currentUser?.aemSubtype {
            // LBP patients: AEM analytics dashboard
            AnalyticsDashboardView(subtype: subtype)
        } else if appState.isNeck {
            // Neck patients: NDI progress + focus areas
            NeckInsightsSection()
        } else if appState.isTension {
            // Tension patients: TSI progress + focus areas
            TensionInsightsSection()
        } else if appState.isShoulder {
            // Shoulder patients: QuickDASH progress + focus areas
            ShoulderInsightsSection()
        } else if appState.isFrozenShoulder {
            // Frozen Shoulder patients: SPADI progress + focus areas
            FrozenShoulderInsightsSection()
        } else if appState.isLateralAnkleSprain {
            // Lateral Ankle Sprain patients: CAIT progress + focus areas
            LateralAnkleSprainInsightsSection()
        } else if appState.isAcl {
            // ACL patients: comprehensive analytics dashboard
            AclAnalyticsView()
        } else {
            // Tendinopathy patients: training overview + phase readiness
            TendinopathyInsightsView(viewModel: viewModel, phaseVM: phaseVM)
        }
    }
}

// MARK: - Neck Insights

struct NeckInsightsSection: View {
    var body: some View {
        VStack(spacing: 20) {
            NdiProgressView()
            ConditionFocusAreasView(config: .neck)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Tension Insights

struct TensionInsightsSection: View {
    var body: some View {
        VStack(spacing: 20) {
            TsiProgressView()
            ConditionFocusAreasView(config: .tension)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Shoulder Insights

struct ShoulderInsightsSection: View {
    var body: some View {
        VStack(spacing: 20) {
            SiProgressView()
            ConditionFocusAreasView(config: .shoulder)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Frozen Shoulder Insights

struct FrozenShoulderInsightsSection: View {
    var body: some View {
        VStack(spacing: 20) {
            FsProgressView()
            ConditionFocusAreasView(config: .frozenShoulder)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Lateral Ankle Sprain Insights

struct LateralAnkleSprainInsightsSection: View {
    var body: some View {
        VStack(spacing: 20) {
            LasProgressView()
            ConditionFocusAreasView(config: .lateralAnkleSprain)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Tendinopathy Insights

struct TendinopathyInsightsView: View {
    let viewModel: DashboardViewModel?
    let phaseVM: PhaseViewModel?

    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        if let viewModel, viewModel.isLoading {
            ProgressSkeletonView()
                .padding(.vertical, 8)
        } else if let stats = viewModel?.progressStats {
            VStack(spacing: 20) {
                trainingOverviewSection(stats)
                if let phaseStatus = viewModel?.phaseStatus {
                    phaseReadinessSection(phaseStatus)
                    phaseInfoSection(phaseStatus.currentPhase)
                }
            }
            .padding(.bottom, 32)
        } else {
            EmptyStateView(
                icon: "chart.bar.xaxis",
                title: appLanguage == "en" ? "No data yet" : "Noch keine Daten",
                message: appLanguage == "en" ? "Analysis will be available after a few training sessions." : "Analyse wird nach einigen Trainingseinheiten verfügbar."
            )
        }
    }

    // MARK: - Training Overview

    private func trainingOverviewSection(_ stats: ProgressStats) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.accent)
                Text(appLanguage == "en" ? "Training Overview" : "Trainings-Übersicht")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Compliance",
                    value: "\(Int(stats.compliancePercent))%",
                    color: stats.compliancePercent >= 66 ? .painGreen : .painAmber
                )

                MetricCard(
                    title: appLanguage == "en" ? "Sessions" : "Trainings",
                    value: "\(stats.totalSessions)",
                    color: .accent
                )

                MetricCard(
                    title: appLanguage == "en" ? "Pain Avg" : "Schmerz Ø",
                    value: String(format: "%.1f", stats.averagePain),
                    color: stats.averagePain <= 3 ? .painGreen : stats.averagePain <= 5 ? .painAmber : .painRed
                )

                MetricCard(
                    title: appLanguage == "en" ? "Last 7 days" : "Letzte 7 Tage",
                    value: "\(stats.lastSevenDays)",
                    color: .accent
                )
            }
        }
    }

    // MARK: - Phase Readiness

    private func phaseReadinessSection(_ status: AdaptivePhaseStatus) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(.accent)
                Text(appLanguage == "en" ? "Phase Readiness" : "Phasen-Bereitschaft")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            HStack {
                Text(status.phaseName)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text(appLanguage == "en" ? "Day \(status.daysInPhase)" : "Tag \(status.daysInPhase)")
                    .font(.appCaptionMedium)
                    .badgeStyle(color: .accent)
            }

            VStack(spacing: 8) {
                criteriaRow(
                    appLanguage == "en" ? "Minimum duration reached" : "Mindestdauer erreicht",
                    met: status.progressionReadiness.minDaysMet
                )
                criteriaRow(
                    appLanguage == "en" ? "Training sessions completed" : "Trainingseinheiten erfüllt",
                    met: status.progressionReadiness.minSessionsMet
                )
                criteriaRow(
                    appLanguage == "en" ? "Pain within target range" : "Schmerz im Zielbereich",
                    met: status.progressionReadiness.painCriteriaMet
                )
                criteriaRow(
                    appLanguage == "en" ? "Sufficient compliance" : "Compliance ausreichend",
                    met: status.progressionReadiness.complianceCriteriaMet
                )
            }

            Text(status.nextEvaluationHint)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle()
    }

    private func criteriaRow(_ label: String, met: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(met ? .painGreen : .textSecondary)
                .font(.appBody)
            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(.textPrimary)
            Spacer()
        }
    }

    // MARK: - Phase Info

    private func phaseInfoSection(_ phase: Int) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.accent)
                Text(appLanguage == "en" ? "Current Phase" : "Aktuelle Phase")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            Text(phaseDescription(for: phase))
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .infoBoxStyle(color: .accent)
    }

    private func phaseDescription(for phase: Int) -> String {
        let isEn = appLanguage == "en"
        switch phase {
        case 1:
            return isEn
                ? "Isometric exercises help reduce pain and gently load the tendon. The goal is a stable foundation for the next phases."
                : "Isometrische Übungen helfen, Schmerzen zu reduzieren und die Sehne schonend zu belasten. Ziel ist eine stabile Basis für die nächsten Phasen."
        case 2:
            return isEn
                ? "Heavy Slow Resistance promotes tendon adaptation through slow, controlled loading. The tendon gradually becomes more resilient."
                : "Heavy Slow Resistance fördert die Sehnenanpassung durch langsame, kontrollierte Belastung. Die Sehne wird schrittweise widerstandsfähiger."
        case 3:
            return isEn
                ? "Eccentric exercises prepare for the return to full activity. The focus is on functional loading and resilience."
                : "Exzentrische Übungen bereiten auf die Rückkehr zur vollen Aktivität vor. Fokus liegt auf funktioneller Belastung und Belastbarkeit."
        default:
            return isEn
                ? "Follow your training plan and monitor your pain progression."
                : "Folgen Sie Ihrem Trainingsplan und achten Sie auf die Schmerzentwicklung."
        }
    }
}
