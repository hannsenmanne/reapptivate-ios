import SwiftUI

struct WorkTimerSettingsSheet: View {
    @Bindable var viewModel: WorkTimerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Startzeit",
                        selection: $viewModel.startTime,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "Endzeit",
                        selection: $viewModel.endTime,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("Arbeitszeit")
                }

                Section {
                    Picker("Intervall", selection: $viewModel.breakIntervalMinutes) {
                        Text("30 Min.").tag(30)
                        Text("45 Min.").tag(45)
                        Text("60 Min.").tag(60)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Pausenintervall")
                } footer: {
                    Text("Wie oft Sie an eine Bewegungspause erinnert werden.")
                }

                Section {
                    Picker("Dauer", selection: $viewModel.breakDurationMinutes) {
                        Text("1 Min.").tag(1)
                        Text("2 Min.").tag(2)
                        Text("3 Min.").tag(3)
                        Text("5 Min.").tag(5)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Pausendauer")
                } footer: {
                    Text("Wie lange jede Bewegungspause dauert.")
                }

                Section {
                    Toggle("Automatisch starten", isOn: Binding(
                        get: { viewModel.autoStartEnabled },
                        set: { viewModel.autoStartEnabled = $0 }
                    ))
                } footer: {
                    Text("Timer startet automatisch innerhalb der Arbeitszeit.")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.appCaption)
                            .foregroundStyle(.painRed)
                    }
                }
            }
            .navigationTitle("Timer-Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
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
