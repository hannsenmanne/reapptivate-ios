import SwiftUI

struct AclWeeklyScheduleCard: View {
    let weeksPostSurgery: Int
    let onStartTodayProgram: ([String]) -> Void
    @AppStorage("appLanguage") private var appLanguage = "de"

    private var dayLabels: [String] {
        appLanguage == "en"
            ? ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            : ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    }

    private var block: AclScheduleData.ScheduleBlock? {
        AclScheduleData.block(forWeek: weeksPostSurgery)
    }

    private var todayIdx: Int {
        AclScheduleData.todayIndex()
    }

    var body: some View {
        if let block {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.accent)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appLanguage == "en" ? "Weekly Rhythm" : "Wochenrhythmus")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Text(appLanguage == "en" ? "Week \(weeksPostSurgery): \(block.title)" : "Woche \(weeksPostSurgery): \(block.title)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()
                }

                // 7-day list
                VStack(spacing: 0) {
                    ForEach(Array(block.days.enumerated()), id: \.offset) { index, day in
                        let isToday = index == todayIdx

                        HStack(spacing: 12) {
                            Text(dayLabels[index])
                                .font(isToday ? .appCaptionBold : .appCaptionMedium)
                                .foregroundStyle(isToday ? .textPrimary : .textSecondary)
                                .frame(width: 24, alignment: .leading)

                            Text(day.label)
                                .font(isToday ? .appSubheadlineMedium : .appSubheadline)
                                .foregroundStyle(
                                    day.isRest ? .textSecondary.opacity(0.6) :
                                    isToday ? .textPrimary : .textSecondary
                                )
                                .lineLimit(1)

                            Spacer()

                            if day.isTraining {
                                Circle()
                                    .fill(isToday ? Color.accent : Color.textSecondary.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                    .accessibilityHidden(true)
                            } else if day.type == .activeRecovery {
                                Circle()
                                    .stroke(isToday ? Color.accent : Color.textSecondary.opacity(0.3), lineWidth: 1)
                                    .frame(width: 6, height: 6)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            isToday ? Color.accent.opacity(0.06) : Color.clear
                        )
                        .overlay(alignment: .leading) {
                            if isToday {
                                Rectangle()
                                    .fill(Color.accent)
                                    .frame(width: 3)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                        if index < block.days.count - 1 {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
                .background(Color.appBg.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))

                // "Start today's program" button
                let today = block.days[todayIdx]
                if today.hasExercises {
                    Button {
                        onStartTodayProgram(today.streamIds)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.appCaption)
                            Text(appLanguage == "en" ? "Start today's program" : "Heutiges Programm starten")
                                .font(.appSubheadlineMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .buttonStyle(.accentFilled)
                    .accessibilityLabel(appLanguage == "en" ? "Start today's training program" : "Heutiges Trainingsprogramm starten")
                    .accessibilityHint(today.label)
                }
            }
            .cardStyle()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(appLanguage == "en" ? "Weekly rhythm, week \(weeksPostSurgery)" : "Wochenrhythmus, Woche \(weeksPostSurgery)")
        }
    }
}
