import SwiftUI

struct NstProgramView: View {
    @Environment(APIClient.self) private var apiClient
    let severity: NeckShoulderSeverity

    @State private var viewModel: NeckShoulderProgramViewModel?
    @State private var selectedTab: ProgramTab = .strengthA

    enum ProgramTab: String, CaseIterable {
        case strengthA = "Kraft A"
        case strengthB = "Kraft B"
        case mobility = "Mobilität"
        case microPauses = "Mikro-Pausen"
    }

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    LoadingView(message: "Programm laden...")
                } else if let error = vm.errorMessage, !vm.hasProgram {
                    noProgramView(vm: vm, error: error)
                } else if vm.hasProgram {
                    programContent(vm: vm)
                } else {
                    noProgramView(vm: vm, error: nil)
                }
            } else {
                LoadingView()
            }
        }
        .task {
            let vm = NeckShoulderProgramViewModel(apiClient: apiClient)
            viewModel = vm
            await vm.loadAll()
        }
    }

    // MARK: - No Program

    @ViewBuilder
    private func noProgramView(vm: NeckShoulderProgramViewModel, error: String?) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(severityColor)

            VStack(spacing: 8) {
                Text("Kein Programm vorhanden")
                    .font(.appTitle3)
                    .foregroundStyle(.textPrimary)

                Text("Erstellen Sie Ihr personalisiertes Nacken-Schulter Programm basierend auf Ihrem Screening-Ergebnis.")
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let error {
                Text(error)
                    .font(.appCaption)
                    .foregroundStyle(.painRed)
            }

            Button {
                Task { await vm.generateProgram() }
            } label: {
                Group {
                    if vm.isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Label("Programm erstellen", systemImage: "plus.circle.fill")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.accentFilled)
            .disabled(vm.isGenerating)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Program Content

    @ViewBuilder
    private func programContent(vm: NeckShoulderProgramViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Program Overview Card
                programOverviewCard(vm: vm)

                // Progression status
                if let message = vm.progressionMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.painGreen)
                        Text(message)
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    .infoBoxStyle(color: .painGreen)
                }

                // Tab selector
                tabSelector

                // Exercise list based on tab
                exerciseSection(vm: vm)
            }
            .padding(16)
        }
        .background(Color.appBg)
        .refreshable {
            await vm.loadAll()
        }
    }

    // MARK: - Overview Card

    @ViewBuilder
    private func programOverviewCard(vm: NeckShoulderProgramViewModel) -> some View {
        if let program = vm.program {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(severityColor)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.appTitle3)
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nacken-Schulter Programm")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                        Text("Woche \(program.currentWeek) von \(program.durationWeeks)")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    Text(severity.displayName)
                        .font(.outfit(.medium, size: 11))
                        .foregroundStyle(severityColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(severityColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                }

                // Week progress bar
                VStack(spacing: 4) {
                    ProgressView(value: Double(program.currentWeek), total: Double(program.durationWeeks))
                        .tint(severityColor)
                    HStack {
                        Text("Fortschritt")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                        Spacer()
                        Text("\(Int((Double(program.currentWeek) / Double(program.durationWeeks)) * 100))%")
                            .font(.appCaptionBold)
                            .foregroundStyle(severityColor)
                    }
                }

                // Quick stats row
                HStack(spacing: 0) {
                    statItem(value: "\(program.strengthFrequency)x", label: "Kraft/Woche")
                    Divider().frame(height: 32)
                    statItem(value: "\(program.mobilityFrequency)x", label: "Mobilität/Tag")
                    Divider().frame(height: 32)
                    statItem(value: "\(program.microPauseIntervalMinutes)'", label: "Mikro-Pausen")
                }

                // Evaluate progression button
                Button {
                    Task { await vm.evaluateProgression() }
                } label: {
                    HStack(spacing: 6) {
                        if vm.isEvaluating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                        }
                        Text("Fortschritt prüfen")
                    }
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(severityColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(severityColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                }
                .disabled(vm.isEvaluating)
            }
            .cardStyle()
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProgramTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.appCaptionMedium)
                            .foregroundStyle(selectedTab == tab ? .white : .textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? severityColor : Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Exercise Section

    @ViewBuilder
    private func exerciseSection(vm: NeckShoulderProgramViewModel) -> some View {
        if let exercises = vm.exercises {
            switch selectedTab {
            case .strengthA:
                strengthSection(section: exercises.programA)
            case .strengthB:
                strengthSection(section: exercises.programB)
            case .mobility:
                mobilitySection(section: exercises.dailyMobility)
            case .microPauses:
                microPauseSection(section: exercises.microPauses)
            }
        } else {
            VStack(spacing: 12) {
                ProgressView("Programm laden...")
                Text("Übungen laden...")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.vertical, 24)
        }
    }

    @ViewBuilder
    private func strengthSection(section: NeckShoulderExerciseConfig.ProgramSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(section.name)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
                if let duration = section.durationMinutes {
                    Text("~\(duration) Min.")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }

            if section.exercises.isEmpty {
                Text("Keine Übungen verfügbar")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(section.exercises) { exercise in
                    NavigationLink {
                        NstExerciseDetailView(exercise: exercise, accentColor: severityColor)
                    } label: {
                        NstExerciseCard(exercise: exercise, accentColor: severityColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func mobilitySection(section: NeckShoulderExerciseConfig.MobilitySection) -> some View {
        NstMobilityView(section: section, accentColor: severityColor)
    }

    @ViewBuilder
    private func microPauseSection(section: NeckShoulderExerciseConfig.MicroPauseSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(severityColor)
                Text("Mikro-Pausen")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text("Alle \(section.intervalMinutes) Min.")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                    Text("\(section.durationMinutes) Min. Dauer")
                        .font(.appCaptionMedium)
                        .foregroundStyle(.textSecondary)
                }
            }
            .padding(10)
            .background(severityColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))

            ForEach(section.exercises) { exercise in
                NavigationLink {
                    NstExerciseDetailView(exercise: exercise, accentColor: severityColor)
                } label: {
                    NstExerciseCard(exercise: exercise, accentColor: severityColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var severityColor: Color {
        switch severity {
        case .mild: .painGreen
        case .moderate: .painAmber
        case .high: .painRed
        }
    }
}

// MARK: - Exercise Card

struct NstExerciseCard: View {
    let exercise: NeckShoulderExercise
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(accentColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: exerciseIcon)
                        .font(.appCaption)
                        .foregroundStyle(accentColor)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let muscle = exercise.targetMuscle {
                        Text(muscle)
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    Text(exercise.detail)
                        .font(.appCaptionMedium)
                        .foregroundStyle(accentColor)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.appCaption2)
                .foregroundStyle(.textSecondary)
        }
        .cardStyle()
    }

    private var exerciseIcon: String {
        if exercise.holdSeconds != nil {
            return "figure.mind.and.body"
        }
        if exercise.equipment != nil {
            return "dumbbell.fill"
        }
        return "figure.strengthtraining.traditional"
    }
}
