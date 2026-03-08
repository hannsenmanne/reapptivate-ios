import SwiftUI

struct SmartDayView: View {
    let smartDay: SmartDayResponse?

    var body: some View {
        VStack(spacing: 20) {
            if let data = smartDay {
                // Day Message + Insight
                dayMessageCard(data)

                // Check-In Summary
                if let checkin = data.morningCheckin {
                    checkinSummaryCard(checkin)
                }

                // Training Day vs Rest Day
                if data.isTrainingDay {
                    trainingDayContent(data)
                } else {
                    restDayContent(data)
                }

                // Work Timer (LBP / Neck / Tension)
                WorkTimerCard()

                // Streak
                streakCard(data.streakInfo)

                // Education Suggestions — hidden until content actually exists
                // if !data.educationSuggestions.isEmpty {
                //     educationSuggestionsCard(data.educationSuggestions)
                // }

                // Training Schedule
                TrainingScheduleCard()
            } else {
                EmptyStateView(
                    icon: "sun.max",
                    title: "Tagesplan wird geladen",
                    message: "Dein personalisierter Tagesplan wird erstellt."
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

    private func checkinSummaryCard(_ checkin: MorningCheckinSummary) -> some View {
        HStack(spacing: 16) {
            checkinPill(label: "Schmerz", value: "\(checkin.painLevel)/10", color: Color.painColor(for: checkin.painLevel))

            if let sleep = checkin.sleepQuality {
                checkinPill(label: "Schlaf", value: "\(sleep)/5", color: .accent)
            }

            if let stiffness = checkin.stiffness {
                checkinPill(label: "Steifheit", value: "\(stiffness)/10", color: .painAmber)
            }

            if let mood = checkin.mood {
                let emojis = ["😫", "😕", "😐", "🙂", "😊"]
                let emoji = mood >= 1 && mood <= 5 ? emojis[mood - 1] : "😐"
                checkinPill(label: "Stimmung", value: emoji, color: .accent)
            }

            Spacer()
        }
        .cardStyle()
    }

    private func checkinPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.appHeadline)
                .foregroundStyle(color)
            Text(label)
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)
        }
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

    private func streakCard(_ streak: StreakInfo) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(streak.current)")
                    .font(.appTitle)
                    .foregroundStyle(.accent)
                Text("Aktuelle Serie")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            VStack(spacing: 4) {
                Text("\(streak.longest)")
                    .font(.appTitle)
                    .foregroundStyle(.textPrimary)
                Text("Längste Serie")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()
        }
        .cardStyle()
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
