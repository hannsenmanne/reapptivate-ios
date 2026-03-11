import SwiftUI

private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}

struct AchievementsView: View {
    @Environment(AppState.self) private var appState
    @State private var milestoneService = MilestoneService()

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Milestone.allCases, id: \.rawValue) { milestone in
                    AchievementCard(
                        milestone: milestone,
                        isEarned: milestoneService.isEarned(milestone),
                        earnedDate: milestoneService.earnedDate(for: milestone)
                    )
                }
            }
            .padding(16)
        }
        .background(Color.appBg)
        .navigationTitle(isEnglishLocale ? "Achievements" : "Erfolge")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let user = appState.currentUser {
                milestoneService.configure(userId: user.id)
            }
        }
    }
}

struct AchievementCard: View {
    let milestone: Milestone
    let isEarned: Bool
    let earnedDate: Date?
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Circle()
                .fill(isEarned ? milestone.color.opacity(0.15) : Color.textSecondary.opacity(0.08))
                .frame(width: iconSize * 1.5, height: iconSize * 1.5)
                .overlay {
                    if isEarned {
                        Image(systemName: milestone.icon)
                            .font(.system(size: iconSize * 0.5))
                            .foregroundStyle(milestone.color)
                    } else {
                        Image(systemName: "questionmark")
                            .font(.system(size: iconSize * 0.5))
                            .foregroundStyle(.textSecondary.opacity(0.4))
                    }
                }

            // Title
            Text(milestone.title)
                .font(.appCaptionMedium)
                .foregroundStyle(isEarned ? .textPrimary : .textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Date or locked
            if isEarned, let date = earnedDate {
                Text(date, style: .date)
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary)
            } else {
                Text(isEnglishLocale ? "Locked" : "Gesperrt")
                    .font(.appCaption2)
                    .foregroundStyle(.textSecondary.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle(padding: 12)
        .grayscale(isEarned ? 0 : 1)
        .overlay {
            if isEarned {
                VStack {
                    HStack {
                        Spacer()
                        ShareLink(item: isEnglishLocale
                            ? "I achieved \"\(milestone.title)\" in Reapptivate!"
                            : "Ich habe \"\(milestone.title)\" in Reapptivate erreicht!"
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                                .padding(8)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}
