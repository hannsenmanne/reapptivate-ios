import SwiftUI

struct WorkTimerSettingsSheet: View {
    @Bindable var viewModel: WorkTimerViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var isSaving = false

    private var isEn: Bool { appLanguage == "en" }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        isEn ? "Start time" : "Startzeit",
                        selection: $viewModel.startTime,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        isEn ? "End time" : "Endzeit",
                        selection: $viewModel.endTime,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text(isEn ? "Working hours" : "Arbeitszeit")
                }

                Section {
                    Picker(isEn ? "Interval" : "Intervall", selection: $viewModel.breakIntervalMinutes) {
                        Text(isEn ? "30 min" : "30 Min.").tag(30)
                        Text(isEn ? "45 min" : "45 Min.").tag(45)
                        Text(isEn ? "60 min" : "60 Min.").tag(60)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(isEn ? "Break interval" : "Pausenintervall")
                } footer: {
                    Text(isEn ? "How often you are reminded to take a movement break." : "Wie oft Sie an eine Bewegungspause erinnert werden.")
                }

                Section {
                    Picker(isEn ? "Duration" : "Dauer", selection: $viewModel.breakDurationMinutes) {
                        Text(isEn ? "1 min" : "1 Min.").tag(1)
                        Text(isEn ? "2 min" : "2 Min.").tag(2)
                        Text(isEn ? "3 min" : "3 Min.").tag(3)
                        Text(isEn ? "5 min" : "5 Min.").tag(5)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(isEn ? "Break duration" : "Pausendauer")
                } footer: {
                    Text(isEn ? "How long each movement break lasts." : "Wie lange jede Bewegungspause dauert.")
                }

                Section {
                    Toggle(isEn ? "Auto-start" : "Automatisch starten", isOn: Binding(
                        get: { viewModel.autoStartEnabled },
                        set: { viewModel.autoStartEnabled = $0 }
                    ))
                } footer: {
                    Text(isEn ? "Timer starts automatically during working hours." : "Timer startet automatisch innerhalb der Arbeitszeit.")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.appCaption)
                            .foregroundStyle(.painRed)
                    }
                }
            }
            .navigationTitle(isEn ? "Timer settings" : "Timer-Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEn ? "Cancel" : "Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEn ? "Save" : "Speichern") {
                        isSaving = true
                        Task {
                            await viewModel.saveSettings()
                            isSaving = false
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
