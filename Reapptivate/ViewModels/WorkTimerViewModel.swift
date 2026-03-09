import SwiftUI
import UserNotifications

@Observable
@MainActor
final class WorkTimerViewModel {
    // MARK: - Settings

    var settings: WorkTimerSettings?
    var startTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    var endTime: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    var breakIntervalMinutes: Int = 60
    var breakDurationMinutes: Int = 3

    // MARK: - Timer State

    var isRunning = false
    var timerStartedAt: Date?
    var nextBreakAt: Date?
    var secondsUntilBreak: Int = 0
    var breaksTakenToday: Int = 0
    var breaksSkippedToday: Int = 0
    var totalBreaksExpected: Int = 0

    // MARK: - Break State

    var isOnBreak = false
    var breakExercises: [WorkTimerBreakExercise] = []
    var allExercises: [WorkTimerBreakExercise] = []
    var breakSecondsRemaining: Int = 0
    var currentBreakNumber: Int = 0
    var snoozesUsed: Int = 0

    // MARK: - Summary

    var todaySummary: WorkTimerDaySummary?
    var showingSummary = false
    var weekHistory: [WorkTimerDaySummary] = []
    var showingHistory = false

    // MARK: - UI

    var isLoading = false
    var showingSettings = false
    var showingBreak = false
    var errorMessage: String?

    // MARK: - Private

    private let apiClient: APIClient
    private var workTimer: Timer?
    private var breakTimer: Timer?

    private static let udKeyIsRunning = "workTimer_isRunning"
    private static let udKeyStartedAt = "workTimer_startedAt"
    private static let udKeyNextBreakAt = "workTimer_nextBreakAt"
    private static let udKeyBreaksTaken = "workTimer_breaksTaken"
    private static let udKeyBreaksSkipped = "workTimer_breaksSkipped"
    private static let udKeyCurrentBreakNumber = "workTimer_currentBreakNumber"
    private static let udKeyDate = "workTimer_date"
    private static let udKeyIsOnBreak = "workTimer_isOnBreak"
    private static let udKeyBreakStartedAt = "workTimer_breakStartedAt"
    private static let udKeyAutoStart = "workTimer_autoStart"
    private static let udKeySnoozesUsed = "workTimer_snoozesUsed"

    private static let maxSnoozes = 2
    private var isAutoStopping = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Init

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    deinit {
        MainActor.assumeIsolated {
            workTimer?.invalidate()
            breakTimer?.invalidate()
        }
    }

    // MARK: - Computed Properties

    var progress: Double {
        guard secondsUntilBreak >= 0 else { return 1.0 }
        let totalInterval = Double(breakIntervalMinutes * 60)
        guard totalInterval > 0 else { return 0 }
        let elapsed = totalInterval - Double(secondsUntilBreak)
        return min(1.0, max(0, elapsed / totalInterval))
    }

    var formattedTimeUntilBreak: String {
        let minutes = max(0, secondsUntilBreak) / 60
        let seconds = max(0, secondsUntilBreak) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedWorkTime: String {
        guard let startedAt = timerStartedAt else { return "0 Min." }
        let elapsed = Int(Date().timeIntervalSince(startedAt))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        if hours > 0 {
            return "\(hours) Std. \(minutes) Min."
        }
        return "\(minutes) Min."
    }

    var adherencePercent: Double {
        let offered = breaksTakenToday + breaksSkippedToday
        guard offered > 0 else { return 0 }
        return Double(breaksTakenToday) / Double(offered) * 100
    }

    var isWithinWorkHours: Bool {
        let calendar = Calendar.current
        let now = Date()
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        guard let startHour = startComponents.hour, let startMin = startComponents.minute,
              let endHour = endComponents.hour, let endMin = endComponents.minute else {
            return false
        }

        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        guard let nowHour = nowComponents.hour, let nowMin = nowComponents.minute else {
            return false
        }

        let nowTotal = nowHour * 60 + nowMin
        let startTotal = startHour * 60 + startMin
        let endTotal = endHour * 60 + endMin

        return nowTotal >= startTotal && nowTotal < endTotal
    }

    var formattedBreakTimeRemaining: String {
        let minutes = max(0, breakSecondsRemaining) / 60
        let seconds = max(0, breakSecondsRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var breakProgress: Double {
        let totalSeconds = isMicroBreak ? Double(microBreakDuration) : Double(breakDurationMinutes * 60)
        guard totalSeconds > 0 else { return 0 }
        let elapsed = totalSeconds - Double(breakSecondsRemaining)
        return min(1.0, max(0, elapsed / totalSeconds))
    }

    var canSnooze: Bool { snoozesUsed < Self.maxSnoozes }

    var isMicroBreak: Bool { currentBreakNumber % 2 == 1 }

    var microBreakDuration: Int { 30 }

    var autoStartEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.udKeyAutoStart) }
        set { UserDefaults.standard.set(newValue, forKey: Self.udKeyAutoStart) }
    }

    var weeklyAdherence: Double {
        guard !weekHistory.isEmpty else { return 0 }
        return weekHistory.map(\.adherencePercent).reduce(0, +) / Double(weekHistory.count)
    }

    var currentStreak: Int {
        var streak = 0
        let sorted = weekHistory.sorted { $0.date > $1.date }
        for day in sorted {
            if day.breaksCompleted > 0 { streak += 1 } else { break }
        }
        return streak
    }

    // MARK: - API: Settings

    func loadSettings() async {
        isLoading = true
        do {
            let response: WorkTimerSettingsResponse = try await apiClient.request(
                APIEndpoints.getWorkTimerSettings()
            )
            settings = response.settings
            applySettings(response.settings)
        } catch {
            // Use defaults if no settings found
            Log.general.info("No work timer settings found, using defaults")
        }
        isLoading = false
    }

    func saveSettings() async {
        let settingsToSave = WorkTimerSettings(
            startTime: formatTime(startTime),
            endTime: formatTime(endTime),
            breakIntervalMinutes: breakIntervalMinutes,
            breakDurationMinutes: breakDurationMinutes,
            isEnabled: true
        )

        do {
            let response: WorkTimerSettingsResponse = try await apiClient.request(
                APIEndpoints.updateWorkTimerSettings(body: settingsToSave)
            )
            settings = response.settings
            applySettings(response.settings)
        } catch {
            errorMessage = "Einstellungen konnten nicht gespeichert werden."
            Log.api.error("Failed to save work timer settings: \(error.localizedDescription)")
        }
    }

    // MARK: - API: Exercises

    func loadExercises() async {
        do {
            let response: WorkTimerExercisesResponse = try await apiClient.request(
                APIEndpoints.getWorkTimerExercises()
            )
            allExercises = response.exercises
        } catch {
            Log.api.error("Failed to load work timer exercises: \(error.localizedDescription)")
        }
    }

    // MARK: - API: History

    func loadHistory() async {
        do {
            let response: WorkTimerHistoryResponse = try await apiClient.request(
                APIEndpoints.getWorkTimerHistory()
            )
            weekHistory = response.history
        } catch {
            Log.api.error("Failed to load work timer history: \(error.localizedDescription)")
        }
    }

    // MARK: - Workday Control

    func startWorkday() {
        let now = Date()
        timerStartedAt = now
        isRunning = true
        breaksTakenToday = 0
        breaksSkippedToday = 0
        currentBreakNumber = 0
        snoozesUsed = 0

        calculateNextBreak(from: now)
        startWorkTimer()
        saveTimerState()
        scheduleBreakNotification()

        AudioService.shared.activateSession()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func stopWorkday() async {
        isRunning = false
        stopWorkTimer()
        stopBreakTimer()
        cancelPendingNotifications()
        AudioService.shared.deactivateSession()

        // Build local summary (backend endpoint returns raw break logs, not aggregated)
        let totalMinutes: Int
        if let started = timerStartedAt {
            totalMinutes = Int(Date().timeIntervalSince(started)) / 60
        } else {
            totalMinutes = 0
        }
        todaySummary = WorkTimerDaySummary(
            date: todayDateString(),
            totalWorkMinutes: totalMinutes,
            breaksOffered: breaksTakenToday + breaksSkippedToday,
            breaksCompleted: breaksTakenToday,
            breaksSkipped: breaksSkippedToday,
            adherencePercent: adherencePercent
        )

        showingSummary = true
        clearTimerState()
    }

    // MARK: - Break Management

    func triggerBreak() {
        currentBreakNumber += 1
        snoozesUsed = 0
        selectBreakExercises()
        breakSecondsRemaining = isMicroBreak ? microBreakDuration : breakDurationMinutes * 60
        isOnBreak = true
        showingBreak = true
        startBreakTimer()
        saveBreakState()

        AudioService.shared.playAlarm()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func completeBreak() async {
        isOnBreak = false
        showingBreak = false
        breaksTakenToday += 1
        stopBreakTimer()
        clearBreakState()

        let log = WorkTimerBreakLog(
            date: DateFormatters.dateOnly.string(from: Date()),
            breakNumber: currentBreakNumber,
            completed: true,
            skipped: false,
            exercisesShown: breakExercises.map(\.id)
        )

        do {
            try await apiClient.requestVoid(APIEndpoints.logWorkTimerBreak(body: log))
        } catch {
            Log.api.error("Failed to log completed break: \(error.localizedDescription)")
        }

        calculateNextBreak(from: Date())
        saveTimerState()
        scheduleBreakNotification()

        AudioService.shared.playComplete()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func skipBreak() async {
        isOnBreak = false
        showingBreak = false
        breaksSkippedToday += 1
        stopBreakTimer()
        clearBreakState()

        let log = WorkTimerBreakLog(
            date: DateFormatters.dateOnly.string(from: Date()),
            breakNumber: currentBreakNumber,
            completed: false,
            skipped: true,
            exercisesShown: breakExercises.map(\.id)
        )

        do {
            try await apiClient.requestVoid(APIEndpoints.logWorkTimerBreak(body: log))
        } catch {
            Log.api.error("Failed to log skipped break: \(error.localizedDescription)")
        }

        calculateNextBreak(from: Date())
        saveTimerState()
        scheduleBreakNotification()
    }

    func snoozeBreak() {
        isOnBreak = false
        showingBreak = false
        stopBreakTimer()
        clearBreakState()
        snoozesUsed += 1

        // Schedule next break in 5 minutes (short snooze, not full interval)
        let next = Date().addingTimeInterval(5 * 60)
        nextBreakAt = next
        secondsUntilBreak = Int(next.timeIntervalSinceNow)

        saveTimerState()
        scheduleBreakNotification()

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func checkAutoStart() {
        guard autoStartEnabled, isWithinWorkHours, !isRunning, settings != nil else { return }
        startWorkday()
    }

    // MARK: - Timer Persistence

    func saveTimerState() {
        let defaults = UserDefaults.standard
        defaults.set(isRunning, forKey: Self.udKeyIsRunning)
        defaults.set(timerStartedAt?.timeIntervalSince1970, forKey: Self.udKeyStartedAt)
        defaults.set(nextBreakAt?.timeIntervalSince1970, forKey: Self.udKeyNextBreakAt)
        defaults.set(breaksTakenToday, forKey: Self.udKeyBreaksTaken)
        defaults.set(breaksSkippedToday, forKey: Self.udKeyBreaksSkipped)
        defaults.set(currentBreakNumber, forKey: Self.udKeyCurrentBreakNumber)
        defaults.set(snoozesUsed, forKey: Self.udKeySnoozesUsed)
        defaults.set(todayDateString(), forKey: Self.udKeyDate)
    }

    func restoreTimerState() {
        let defaults = UserDefaults.standard

        guard defaults.bool(forKey: Self.udKeyIsRunning) else { return }

        let savedDate = defaults.string(forKey: Self.udKeyDate) ?? ""
        guard savedDate == todayDateString() else {
            // Different day — clear stale state
            clearTimerState()
            return
        }

        let startedAtInterval = defaults.double(forKey: Self.udKeyStartedAt)
        guard startedAtInterval > 0 else {
            clearTimerState()
            return
        }

        timerStartedAt = Date(timeIntervalSince1970: startedAtInterval)
        breaksTakenToday = defaults.integer(forKey: Self.udKeyBreaksTaken)
        breaksSkippedToday = defaults.integer(forKey: Self.udKeyBreaksSkipped)
        currentBreakNumber = defaults.integer(forKey: Self.udKeyCurrentBreakNumber)
        snoozesUsed = defaults.integer(forKey: Self.udKeySnoozesUsed)
        isRunning = true

        // Check if we were in the middle of a break
        if defaults.bool(forKey: Self.udKeyIsOnBreak) {
            let breakStartInterval = defaults.double(forKey: Self.udKeyBreakStartedAt)
            if breakStartInterval > 0 {
                let breakStarted = Date(timeIntervalSince1970: breakStartInterval)
                let elapsed = Int(Date().timeIntervalSince(breakStarted))
                let totalBreakSeconds = isMicroBreak ? microBreakDuration : breakDurationMinutes * 60
                let remaining = totalBreakSeconds - elapsed

                if remaining > 0 {
                    // Break still in progress — resume it
                    breakSecondsRemaining = remaining
                    selectBreakExercises()
                    isOnBreak = true
                    showingBreak = true
                    startBreakTimer()
                    startWorkTimer()
                    AudioService.shared.activateSession()
                    return
                }
            }
            // Break expired while app was closed — count it
            if isMicroBreak {
                breaksTakenToday += 1 // micro-breaks auto-complete
            } else {
                breaksSkippedToday += 1 // regular breaks expire as skipped
            }
            clearBreakState()
        }

        let nextBreakInterval = defaults.double(forKey: Self.udKeyNextBreakAt)
        if nextBreakInterval > 0 {
            let nextBreak = Date(timeIntervalSince1970: nextBreakInterval)
            if nextBreak > Date() {
                nextBreakAt = nextBreak
                secondsUntilBreak = Int(nextBreak.timeIntervalSinceNow)
            } else {
                // Missed break(s) — trigger the last due one
                let missedCount = missedBreakCount(since: nextBreak)
                if missedCount > 1 {
                    breaksSkippedToday += (missedCount - 1)
                    currentBreakNumber += (missedCount - 1)
                }
                triggerBreak()
            }
        } else {
            calculateNextBreak(from: Date())
        }

        startWorkTimer()
        scheduleBreakNotification()
        AudioService.shared.activateSession()
    }

    // MARK: - Foreground Return

    func handleForegroundReturn() {
        guard isRunning else { return }

        if isOnBreak {
            // Recalculate break time remaining from persisted start time
            let defaults = UserDefaults.standard
            let breakStartInterval = defaults.double(forKey: Self.udKeyBreakStartedAt)
            if breakStartInterval > 0 {
                let breakStarted = Date(timeIntervalSince1970: breakStartInterval)
                let elapsed = Int(Date().timeIntervalSince(breakStarted))
                let totalBreakSeconds = isMicroBreak ? microBreakDuration : breakDurationMinutes * 60
                breakSecondsRemaining = max(0, totalBreakSeconds - elapsed)
            }
            // Restart break timer (invalidated in background)
            if breakTimer == nil {
                startBreakTimer()
            }
            return
        }

        if let nextBreak = nextBreakAt {
            secondsUntilBreak = max(0, Int(nextBreak.timeIntervalSinceNow))

            if secondsUntilBreak <= 0 {
                triggerBreak()
                return
            }
        }

        // Timer could have been invalidated in background
        if workTimer == nil {
            startWorkTimer()
        }

        saveTimerState()
    }

    // MARK: - Local Notifications

    func scheduleBreakNotification() {
        guard let nextBreak = nextBreakAt else { return }

        let content = UNMutableNotificationContent()
        content.title = "Zeit für eine Pause!"
        content.body = "Machen Sie eine kurze Bewegungspause für Ihren Rücken und Nacken."
        content.sound = .default
        content.categoryIdentifier = "WORK_TIMER_BREAK"

        let interval = nextBreak.timeIntervalSinceNow
        guard interval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "work_timer_break_\(currentBreakNumber + 1)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Log.notification.error("Failed to schedule break notification: \(error.localizedDescription)")
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                Log.notification.error("Notification permission error: \(error.localizedDescription)")
            }
            Log.notification.info("Notification permission granted: \(granted)")
        }
    }

    // MARK: - Private: Timer Management

    private func startWorkTimer() {
        stopWorkTimer()
        workTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.workTimerTick()
            }
        }
    }

    private func stopWorkTimer() {
        workTimer?.invalidate()
        workTimer = nil
    }

    private func startBreakTimer() {
        stopBreakTimer()
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.breakTimerTick()
            }
        }
    }

    private func stopBreakTimer() {
        breakTimer?.invalidate()
        breakTimer = nil
    }

    private func workTimerTick() {
        guard isRunning, !isOnBreak else { return }

        // Auto-stop when work hours end
        if !isWithinWorkHours {
            autoStopWorkday()
            return
        }

        if let nextBreak = nextBreakAt {
            secondsUntilBreak = max(0, Int(nextBreak.timeIntervalSinceNow))

            if secondsUntilBreak <= 0 {
                triggerBreak()
            }
        }
    }

    private func autoStopWorkday() {
        guard !isAutoStopping else { return }
        isAutoStopping = true
        Task {
            await stopWorkday()
            isAutoStopping = false
        }
    }

    private func breakTimerTick() {
        guard isOnBreak else { return }
        breakSecondsRemaining -= 1

        if breakSecondsRemaining <= 0 {
            breakSecondsRemaining = 0
            // Auto-complete the break
            Task { await completeBreak() }
        }
    }

    // MARK: - Private: Break Calculation

    private func calculateNextBreak(from date: Date) {
        let next = date.addingTimeInterval(Double(breakIntervalMinutes * 60))
        nextBreakAt = next
        secondsUntilBreak = Int(next.timeIntervalSinceNow)
    }

    private func selectBreakExercises() {
        guard !allExercises.isEmpty else {
            breakExercises = []
            return
        }

        // Seed based on date + break number for consistent rotation
        let dayString = todayDateString()
        var seed = dayString.hashValue &+ currentBreakNumber
        seed = seed ^ (seed >> 16)

        var rng = SeededRandomNumberGenerator(seed: UInt64(bitPattern: Int64(seed)))
        let shuffled = allExercises.shuffled(using: &rng)
        breakExercises = Array(shuffled.prefix(isMicroBreak ? 1 : 3))
    }

    private func missedBreakCount(since date: Date) -> Int {
        let elapsed = Date().timeIntervalSince(date)
        let intervalSeconds = Double(breakIntervalMinutes * 60)
        guard intervalSeconds > 0 else { return 0 }
        return max(0, Int(elapsed / intervalSeconds))
    }

    // MARK: - Private: Helpers

    private func applySettings(_ s: WorkTimerSettings) {
        breakIntervalMinutes = s.breakIntervalMinutes
        breakDurationMinutes = s.breakDurationMinutes

        if let start = Self.timeFormatter.date(from: s.startTime) {
            startTime = start
        }
        if let end = Self.timeFormatter.date(from: s.endTime) {
            endTime = end
        }
    }

    private func formatTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    private func todayDateString() -> String {
        DateFormatters.dateOnly.string(from: Date())
    }

    private func saveBreakState() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Self.udKeyIsOnBreak)
        defaults.set(Date().timeIntervalSince1970, forKey: Self.udKeyBreakStartedAt)
        saveTimerState()
    }

    private func clearBreakState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.udKeyIsOnBreak)
        defaults.removeObject(forKey: Self.udKeyBreakStartedAt)
    }

    private func clearTimerState() {
        Self.clearPersistedState()
    }

    /// Clear all persisted work timer state from UserDefaults.
    /// Called on logout to prevent state bleeding between users.
    static func clearPersistedState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: udKeyIsRunning)
        defaults.removeObject(forKey: udKeyStartedAt)
        defaults.removeObject(forKey: udKeyNextBreakAt)
        defaults.removeObject(forKey: udKeyBreaksTaken)
        defaults.removeObject(forKey: udKeyBreaksSkipped)
        defaults.removeObject(forKey: udKeyCurrentBreakNumber)
        defaults.removeObject(forKey: udKeyDate)
        defaults.removeObject(forKey: udKeyIsOnBreak)
        defaults.removeObject(forKey: udKeyBreakStartedAt)
        defaults.removeObject(forKey: udKeyAutoStart)
        defaults.removeObject(forKey: udKeySnoozesUsed)
    }

    private func cancelPendingNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix("work_timer_break_") }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}

// MARK: - Seeded Random Number Generator

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
