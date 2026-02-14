@preconcurrency import UserNotifications
import SwiftUI

@Observable
@MainActor
final class NotificationService {
    var isAuthorized = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    static let shared = NotificationService()

    private init() {}

    // MARK: - Permission

    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            authorizationStatus = granted ? .authorized : .denied
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule Training Reminders

    func scheduleReminders(days: [Int], hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()

        // Remove existing reminders
        center.removePendingNotificationRequests(withIdentifiers: (1...7).map { "training-day-\($0)" })

        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Training-Erinnerung"
        content.body = "Zeit für Ihre Übungen! Starten Sie jetzt Ihr Training."
        content.sound = .default
        content.categoryIdentifier = "TRAINING_REMINDER"

        for day in days {
            var dateComponents = DateComponents()
            dateComponents.weekday = day // 1=Sunday, 2=Monday, ...
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "training-day-\(day)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    // MARK: - Streak-Ending Alert

    func scheduleStreakEndingAlert(streakCount: Int, for date: Date) async {
        guard isAuthorized else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak-ending"])

        let content = UNMutableNotificationContent()
        content.title = "Serie endet heute!"
        content.body = "Trainieren Sie heute, um Ihre \(streakCount)-Tage-Serie zu erhalten."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try? await center.add(
            UNNotificationRequest(identifier: "streak-ending", content: content, trigger: trigger)
        )
    }

    func cancelStreakEndingAlert() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak-ending"])
    }

    // MARK: - Cancel All

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Test Notification

    func sendTestNotification() async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Test-Benachrichtigung"
        content.body = "Ihre Benachrichtigungen funktionieren!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Open Settings

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
