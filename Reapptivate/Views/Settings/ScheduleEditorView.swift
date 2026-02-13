import SwiftUI

struct ScheduleEditorView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var selectedDays: Set<Int> = [] // 1=Sunday, 2=Monday, ...
    @State private var reminderTime = Date()
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSaved = false

    private let dayNames = [
        (2, "Montag"), (3, "Dienstag"), (4, "Mittwoch"),
        (5, "Donnerstag"), (6, "Freitag"), (7, "Samstag"), (1, "Sonntag")
    ]

    var body: some View {
        List {
            // Day selection
            Section("Trainingstage") {
                ForEach(dayNames, id: \.0) { dayNum, dayName in
                    Button {
                        if selectedDays.contains(dayNum) {
                            selectedDays.remove(dayNum)
                        } else {
                            selectedDays.insert(dayNum)
                        }
                    } label: {
                        HStack {
                            Text(dayName)
                                .foregroundStyle(.textPrimary)
                            Spacer()
                            if selectedDays.contains(dayNum) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                }
            }

            // Time
            Section("Erinnerungszeit") {
                DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }

            // Save
            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else if showSaved {
                            Label("Gespeichert", systemImage: "checkmark")
                                .foregroundStyle(.painGreen)
                        } else {
                            Text("Speichern")
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving || selectedDays.isEmpty)
            }
        }
        .navigationTitle("Trainingsplan")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSchedule()
        }
    }

    private func loadSchedule() async {
        isLoading = true
        do {
            let schedule: UserSchedule = try await apiClient.request(APIEndpoints.getSchedule())
            selectedDays = Set(schedule.availableDays)
            // Parse time from preferredTimes
            if let time = schedule.preferredTimes.first {
                let parts = time.split(separator: ":")
                if parts.count >= 2,
                   let hour = Int(parts[0]),
                   let minute = Int(parts[1]) {
                    var dateComponents = DateComponents()
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    if let date = Calendar.current.date(from: dateComponents) {
                        reminderTime = date
                    }
                }
            }
        } catch {
            // Default: Mon/Wed/Fri at 9:00
            selectedDays = [2, 4, 6]
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            if let date = Calendar.current.date(from: components) {
                reminderTime = date
            }
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        let timeString = String(format: "%02d:%02d", hour, minute)

        let request = ScheduleRequest(
            availableDays: Array(selectedDays).sorted(),
            preferredTimes: [timeString],
            notificationsEnabled: true
        )

        do {
            let _: UserSchedule = try await apiClient.request(APIEndpoints.updateSchedule(body: request))

            // Update notifications
            await NotificationService.shared.scheduleReminders(
                days: Array(selectedDays),
                hour: hour,
                minute: minute
            )

            showSaved = true
            try? await Task.sleep(for: .seconds(2))
            showSaved = false
        } catch {
            // Try create instead of update
            do {
                let _: UserSchedule = try await apiClient.request(APIEndpoints.createSchedule(body: request))
                showSaved = true
                try? await Task.sleep(for: .seconds(2))
                showSaved = false
            } catch {
                // Silent fail
            }
        }
        isSaving = false
    }
}
