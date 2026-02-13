import SwiftUI

struct ProgramTab: View {
    @Environment(AppState.self) private var appState
    let exerciseVM: ExerciseViewModel?
    var onExerciseLogged: (() -> Void)?

    @State private var activeSheet: ExerciseSheet?

    enum ExerciseSheet: Identifiable {
        case progressLog(ExerciseWithPhase)
        case detail(ExerciseWithPhase)

        var id: String {
            switch self {
            case .progressLog(let e): "log-\(e.id)"
            case .detail(let e): "detail-\(e.id)"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // AEM Profile (LBP)
            if appState.isLbp, let subtype = appState.currentUser?.aemSubtype {
                AemProfileQuickCard(subtype: subtype)
            }

            // NDI Profile (Neck)
            if appState.isNeck, let severity = appState.currentUser?.ndiSeverity {
                NdiProfileQuickCard(severity: severity)
            }

            // Exercise list by phase
            if let exerciseVM, !exerciseVM.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ubungsprogramm")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)

                        Spacer()

                        Text("\(exerciseVM.completedCount)/\(exerciseVM.totalCount) erledigt")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }

                    ForEach(Array(exerciseVM.exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseCardView(
                            exercise: exercise,
                            index: index,
                            isCompleted: exerciseVM.isCompleted(exercise.id),
                            userSubtype: appState.currentUser?.aemSubtype,
                            onLog: {
                                activeSheet = .progressLog(exercise)
                            },
                            onDetail: {
                                activeSheet = .detail(exercise)
                            }
                        )
                    }
                }
            } else {
                EmptyStateView(
                    icon: "figure.strengthtraining.traditional",
                    title: "Kein Programm",
                    message: "Ihr Ubungsprogramm wird geladen..."
                )
            }

            // LBP Enhancements (Fear Hierarchy, Pacing, Micro-Modules)
            if appState.isLbp, let subtype = appState.currentUser?.aemSubtype {
                LbpEnhancementsView(subtype: subtype)
            }
        }
        .padding(.bottom, 32)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .progressLog(let exercise):
                ProgressLogSheet(
                    exercise: exercise,
                    maxPainLevel: maxPainLevel,
                    showSymptomResponse: appState.isNeck,
                    onSuccess: {
                        exerciseVM?.markCompleted(exercise.id)
                        onExerciseLogged?()
                    }
                )
            case .detail(let exercise):
                NavigationStack {
                    ExerciseDetailView(
                        exercise: exercise,
                        onLog: {
                            activeSheet = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                activeSheet = .progressLog(exercise)
                            }
                        },
                        onStartSession: {
                            activeSheet = nil
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fertig") { activeSheet = nil }
                        }
                    }
                }
            }
        }
    }

    private var maxPainLevel: Int {
        appState.currentUser?.aemSubtype?.maxPainLevel ?? 3
    }
}

// MARK: - Quick Profile Cards

struct AemProfileQuickCard: View {
    let subtype: AemSubtype

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous)
                .fill(Color.subtypeColor(for: subtype))
                .frame(width: 40, height: 40)
                .overlay {
                    subtypeIcon
                        .font(.appBody)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("AEM-Profil")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Text(subtype.displayName)
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.textPrimary)
            }

            Spacer()

            Text("Max. \(subtype.maxPainLevel)/10")
                .font(.appCaptionMedium)
                .foregroundStyle(Color.subtypeColor(for: subtype))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.subtypeColor(for: subtype).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
        }
        .accentCardStyle(color: Color.subtypeColor(for: subtype))
    }

    @ViewBuilder
    var subtypeIcon: some View {
        switch subtype {
        case .FAR: Image(systemName: "magnifyingglass")
        case .DER: Image(systemName: "timer")
        case .EER: Image(systemName: "chart.bar")
        case .AR: Image(systemName: "checkmark.circle")
        }
    }
}

struct NdiProfileQuickCard: View {
    let severity: NdiSeverityGrade

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous)
                .fill(Color.severityColor(for: severity))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "figure.walk")
                        .font(.appBody)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("NDI-Schweregrad")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Text(severity.displayName)
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.textPrimary)
            }

            Spacer()
        }
        .accentCardStyle(color: Color.severityColor(for: severity))
    }
}
