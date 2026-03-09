@preconcurrency import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationDelegate()

    var onBreakComplete: (() -> Void)?
    var onBreakSnooze: (() -> Void)?
    var onBreakSkip: (() -> Void)?

    // Show notifications while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.content.categoryIdentifier == "WORK_TIMER_BREAK" else { return }

        switch response.actionIdentifier {
        case "COMPLETE_BREAK":
            await MainActor.run { onBreakComplete?() }
        case "SNOOZE_BREAK":
            await MainActor.run { onBreakSnooze?() }
        case "SKIP_BREAK":
            await MainActor.run { onBreakSkip?() }
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself — treat as wanting to start the break
            await MainActor.run { onBreakComplete?() }
        default:
            break
        }
    }
}
