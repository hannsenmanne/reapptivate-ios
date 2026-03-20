@preconcurrency import UserNotifications

@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    var onBreakComplete: (() -> Void)?
    var onBreakSnooze: (() -> Void)?
    var onBreakSkip: (() -> Void)?

    // Show notifications while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // Handle notification actions
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.content.categoryIdentifier == "WORK_TIMER_BREAK" else { return }

        let actionId = response.actionIdentifier
        await MainActor.run {
            switch actionId {
            case UNNotificationDefaultActionIdentifier:
                // User tapped notification banner — just open the app.
                // handleForegroundReturn() will show the break with correct timing.
                break
            case "COMPLETE_BREAK":
                onBreakComplete?()
            case "SNOOZE_BREAK":
                onBreakSnooze?()
            case "SKIP_BREAK":
                onBreakSkip?()
            default:
                break
            }
        }
    }
}
