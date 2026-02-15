import SwiftUI
import StoreKit

@Observable
@MainActor
final class RatingService {
    @ObservationIgnored
    @AppStorage("rating_prompt_count") private var promptCount: Int = 0

    @ObservationIgnored
    @AppStorage("rating_last_prompt_date") private var lastPromptDate: String = ""

    private let maxPrompts = 3
    private let cooldownDays = 30

    /// Checks conditions and triggers App Store rating prompt if appropriate.
    func checkAndPrompt(totalSessions: Int, compliancePercent: Double) {
        guard promptCount < maxPrompts else { return }
        guard isCooldownExpired() else { return }

        let qualifies =
            (totalSessions >= 10 && compliancePercent >= 70) ||
            totalSessions >= 25

        guard qualifies else { return }

        // Request review via StoreKit
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            SKStoreReviewController.requestReview(in: scene)
            promptCount += 1
            lastPromptDate = ISO8601DateFormatter().string(from: Date())
        }
    }

    private func isCooldownExpired() -> Bool {
        guard !lastPromptDate.isEmpty else { return true }
        guard let lastDate = ISO8601DateFormatter().date(from: lastPromptDate) else { return true }
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince >= cooldownDays
    }
}
