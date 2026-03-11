import SwiftUI

struct SmartDayView: View {
    let smartDay: SmartDayResponse?
    let completedCount: Int
    let totalCount: Int
    let onNavigateToProgram: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            if let data = smartDay {
                // Day Message + Insight
                dayMessageCard(data)

                // Streak
                streakCard(data.streakInfo)

                // Heutiges Programm
                if data.isTrainingDay && totalCount > 0 {
                    TodaysPlanCard(
                        completedCount: completedCount,
                        totalCount: totalCount,
                        onTap: { onNavigateToProgram?() }
                    )
                } else if !data.isTrainingDay {
                    RestDayCard()
                }

                // Work Timer (LBP / Neck / Tension)
                WorkTimerCard()

                // Training Schedule
                TrainingScheduleCard()
            } else {
                EmptyStateView(
                    icon: "sun.max",
                    title: "Tagesplan wird geladen",
                    message: "Ihr personalisierter Tagesplan wird erstellt."
                )
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Cards

    private func dayMessageCard(_ data: SmartDayResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: data.isTrainingDay ? "figure.strengthtraining.traditional" : "leaf.fill")
                    .font(.appTitle2)
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)

                Text(data.isTrainingDay ? "Trainingstag" : "Ruhetag")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Spacer()
            }

            Text(data.dayMessage)
                .font(.appBody)
                .foregroundStyle(.textPrimary)

            Text(data.dayInsight)
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)

            if let hint = data.progressHint {
                Text(hint)
                    .font(.appCaption)
                    .foregroundStyle(.accent)
            }

            // ACL Context
            if let acl = data.aclContext {
                HStack(spacing: 16) {
                    VStack {
                        Text("\(acl.weeksPostSurgery)")
                            .font(.appTitle2)
                            .foregroundStyle(.accent)
                        Text("Wochen post-OP")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    VStack {
                        Text("M\(acl.currentMilestone)")
                            .font(.appTitle2)
                            .foregroundStyle(.accent)
                        Text("Meilenstein")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    if let hint = acl.nextMilestoneHint {
                        VStack {
                            Image(systemName: "arrow.right")
                                .font(.appBody)
                                .foregroundStyle(.textSecondary)
                            Text(hint)
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .cardStyle()
    }

    private func trainingDayContent(_ data: SmartDayResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Empfohlene Reihenfolge")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            if data.exerciseOrder.isEmpty {
                Text("Keine Übungen für heute geplant.")
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
            } else {
                ForEach(Array(data.exerciseOrder.enumerated()), id: \.offset) { index, exerciseId in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.appCaptionMedium)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.accent)
                            .clipShape(Circle())

                        Text(exerciseId)
                            .font(.appBody)
                            .foregroundStyle(.textPrimary)

                        Spacer()
                    }
                }
            }
        }
        .cardStyle()
    }

    private func restDayContent(_ data: SmartDayResponse) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 32))
                .foregroundStyle(.accent)
                .accessibilityHidden(true)

            Text("Erholungstag")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            Text("Heute ist ein guter Tag zur Erholung. Nutze die Zeit für leichte Bewegung oder Entspannung.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    @ScaledMetric(relativeTo: .body) private var flameSize: CGFloat = 36

    private func streakCard(_ streak: StreakInfo) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundStyle(streak.current > 0 ? Color.painAmber : Color.textSecondary)
                .frame(width: flameSize, height: flameSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(streak.current)")
                        .font(.appTitle2)
                        .foregroundStyle(.textPrimary)
                    Text(streak.current == 1 ? "Tag Streak" : "Tage Streak")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                }

                if streak.longest > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.appCaption2)
                            .foregroundStyle(Color.painAmber)
                            .accessibilityHidden(true)
                        Text("Rekord: \(streak.longest)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Streak: \(streak.current) \(streak.current == 1 ? "Tag" : "Tage"), Rekord: \(streak.longest)")
    }

    private func educationSuggestionsCard(_ suggestions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Empfohlene Lektüre")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
            }

            ForEach(suggestions, id: \.self) { suggestion in
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.appCaption)
                        .foregroundStyle(.accent)
                    Text(educationSuggestionTitle(for: suggestion))
                        .font(.appBody)
                        .foregroundStyle(.textPrimary)
                }
            }
        }
        .cardStyle()
    }

    private func educationSuggestionTitle(for id: String) -> String {
        // Phase intro patterns: phase_1_intro, phase_2_intro, phase_3_intro
        if let match = id.wholeMatch(of: /phase_(\d+)_intro/) {
            return "Einführung in Phase \(match.1)"
        }

        let titles: [String: String] = [
            "motivation_adherence": "Motivation & Durchhalten",
            "exposure_principles": "Prinzipien der Exposition",
            "pacing_strategies": "Pacing-Strategien",
        ]

        return titles[id] ?? id.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
