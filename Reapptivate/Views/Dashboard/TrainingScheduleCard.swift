import SwiftUI

struct TrainingScheduleCard: View {
    @Environment(APIClient.self) private var apiClient

    @State private var selectedDays: Set<Int> = [] // 1=Sunday, 2=Monday, ...
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? .now
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSaved = false
    @State private var showError = false
    @State private var hasExistingSchedule = false
    @State private var saveTask: Task<Void, Never>?

    // Mo=2, Di=3, Mi=4, Do=5, Fr=6, Sa=7, So=1
    private let days: [(id: Int, label: String)] = [
        (2, "Mo"), (3, "Di"), (4, "Mi"),
        (5, "Do"), (6, "Fr"), (7, "Sa"), (1, "So")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.accent)
                Text("Trainingstage")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            // Day buttons
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Zeitplan laden...")
                    Spacer()
                }
                .frame(height: 44)
            } else {
                HStack(spacing: 8) {
                    ForEach(days, id: \.id) { day in
                        DayButton(
                            label: day.label,
                            isSelected: selectedDays.contains(day.id),
                            action: { toggleDay(day.id) }
                        )
                    }
                }

                // Reminder time row
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.appCaption)
                        .foregroundStyle(.accent)
                    Text("Erinnerung")
                        .font(.appSubheadline)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: reminderTime) {
                            scheduleAutoSave()
                        }
                }

                // Save confirmation
                if isSaving {
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                        Text("Speichern...")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                        Spacer()
                    }
                    .transition(.opacity)
                } else if showSaved {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.painGreen)
                        Text("Gespeichert")
                            .font(.appCaption)
                            .foregroundStyle(.painGreen)
                        Spacer()
                    }
                    .transition(.opacity)
                } else if showError {
                    HStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.painRed)
                        Text("Speichern fehlgeschlagen")
                            .font(.appCaption)
                            .foregroundStyle(.painRed)
                        Spacer()
                    }
                    .transition(.opacity)
                }
            }
        }
        .cardStyle()
        .animation(.easeInOut(duration: 0.2), value: showSaved)
        .animation(.easeInOut(duration: 0.2), value: isSaving)
        .task {
            await loadSchedule()
        }
    }

    // MARK: - Day Toggle

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        scheduleAutoSave()
    }

    // MARK: - Auto-Save with Debounce

    private func scheduleAutoSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await save()
        }
    }

    // MARK: - Load

    private func loadSchedule() async {
        isLoading = true
        do {
            let schedule: UserSchedule = try await apiClient.request(APIEndpoints.getSchedule())
            selectedDays = Set(schedule.availableDays)
            hasExistingSchedule = true

            if let time = schedule.preferredTimes.first {
                let parts = time.split(separator: ":")
                if parts.count >= 2,
                   let hour = Int(parts[0]),
                   let minute = Int(parts[1]),
                   let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) {
                    reminderTime = date
                }
            }
        } catch {
            // Defaults: Mon/Wed/Fri at 9:00
            selectedDays = [2, 4, 6]
            hasExistingSchedule = false
        }
        isLoading = false
    }

    // MARK: - Save

    private func save() async {
        guard !selectedDays.isEmpty else { return }
        isSaving = true

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        let timeString = String(format: "%02d:%02d", hour, minute)

        let body = ScheduleRequest(
            availableDays: Array(selectedDays).sorted(),
            preferredTimes: [timeString],
            notificationsEnabled: true
        )

        do {
            if hasExistingSchedule {
                let _: UserSchedule = try await apiClient.request(APIEndpoints.updateSchedule(body: body))
            } else {
                let _: UserSchedule = try await apiClient.request(APIEndpoints.createSchedule(body: body))
                hasExistingSchedule = true
            }

            // Request notification permission if needed, then schedule
            let notifService = NotificationService.shared
            await notifService.checkStatus()
            if !notifService.isAuthorized {
                let _ = await notifService.requestPermission()
            }
            await notifService.scheduleReminders(days: Array(selectedDays), hour: hour, minute: minute)

            showSaved = true
            try? await Task.sleep(for: .seconds(2))
            showSaved = false
        } catch {
            showError = true
            try? await Task.sleep(for: .seconds(2))
            showError = false
        }
        isSaving = false
    }
}

// MARK: - Day Button

private struct DayButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.appCaptionMedium)
                .foregroundStyle(isSelected ? .white : .textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color.accent : Color.gray100)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
