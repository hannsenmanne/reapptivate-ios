import SwiftUI

struct ScheduleEditorView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var selectedDays: Set<Int> = [] // 1=Sunday, 2=Monday, ...
    @State private var reminderTime = Date()
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSaved = false
    @State private var showError = false

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

            // Validation message
            if selectedDays.isEmpty {
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.textSecondary)
                        Text("Wählen Sie mindestens einen Trainingstag aus.")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }

            // Save
            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView("Zeitplan laden...")
                        } else if showSaved {
                            Label("Gespeichert", systemImage: "checkmark")
                                .foregroundStyle(.painGreen)
                        } else if showError {
                            Label("Fehlgeschlagen", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.painRed)
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
            let schedule: ScheduleResponse = try await apiClient.request(APIEndpoints.getSchedule())
            // Convert JS weekday (0-6) to iOS weekday (1-7) for display
            selectedDays = Set(schedule.iosWeekdays)
        } catch {
            // Default: Mon/Wed/Fri (iOS convention)
            selectedDays = [2, 4, 6]
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)

        // Convert iOS weekdays (1-7) to JS convention (0-6) for backend
        let body = ScheduleUpdateRequest.fromIOSWeekdays(Array(selectedDays))

        do {
            let _: ScheduleResponse = try await apiClient.request(APIEndpoints.updateSchedule(body: body))

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
            showError = true
            try? await Task.sleep(for: .seconds(2))
            showError = false
        }
        isSaving = false
    }
}
