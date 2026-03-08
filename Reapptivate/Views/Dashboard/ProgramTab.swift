import SwiftUI

struct ProgramTab: View {
    @Environment(AppState.self) private var appState
    let exerciseVM: ExerciseViewModel?
    var onExerciseLogged: (() -> Void)?

    @State private var activeSheet: ExerciseSheet?
    @State private var pendingSheet: ExerciseSheet?

    enum ExerciseSheet: Identifiable, Equatable {
        case progressLog(ExerciseWithPhase)
        case detail(ExerciseWithPhase)
        case session(ExerciseWithPhase)
        case customProgressLog(CustomExercise)

        var id: String {
            switch self {
            case .progressLog(let e): "log-\(e.id)"
            case .detail(let e): "detail-\(e.id)"
            case .session(let e): "session-\(e.id)"
            case .customProgressLog(let e): "custom-log-\(e.id)"
            }
        }

        static func == (lhs: ExerciseSheet, rhs: ExerciseSheet) -> Bool {
            lhs.id == rhs.id
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // AEM Profile (LBP)
            if appState.isLbp, let subtype = appState.currentUser?.aemSubtype {
                AemProfileQuickCard(subtype: subtype)
                    .cardEntryAnimation(index: 0)
            }

            // NDI Profile (Neck)
            if appState.isNeck, let severity = appState.currentUser?.ndiSeverity {
                NdiProfileQuickCard(severity: severity)
                    .cardEntryAnimation(index: 0)
            }

            // Tendinopathy Profile
            if !appState.isLbp && !appState.isNeck, let user = appState.currentUser {
                TendinopathyProfileQuickCard(
                    tendinopathyType: user.tendinopathyType,
                    currentPhase: user.currentPhase,
                    maxPhase: user.maxPhase
                )
                .cardEntryAnimation(index: 0)
            }

            // Exercise list by phase
            if let exerciseVM, !exerciseVM.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Übungsprogramm")
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
                        .cardEntryAnimation(index: index + 1)
                    }
                }
            } else {
                EmptyStateView(
                    icon: "figure.strengthtraining.traditional",
                    title: "Kein Programm",
                    message: "Ihr Übungsprogramm wird geladen..."
                )
            }

            // Custom exercises from therapist
            if let exerciseVM, !exerciseVM.customExercises.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Zusätzliche Übungen")
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)
                            Text("Vom Therapeuten")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                        Spacer()
                    }

                    ForEach(Array(exerciseVM.customExercises.enumerated()), id: \.element.id) { index, exercise in
                        CustomExerciseCardView(
                            exercise: exercise,
                            index: index,
                            isCompleted: exerciseVM.isCustomExerciseCompleted(exercise),
                            onLog: {
                                activeSheet = .customProgressLog(exercise)
                            }
                        )
                    }
                }
            }

            // LBP Enhancements (Fear Hierarchy, Pacing, Micro-Modules)
            if appState.isLbp, let subtype = appState.currentUser?.aemSubtype {
                LbpEnhancementsView(subtype: subtype)
            }
        }
        .padding(.bottom, 32)
        .sheet(item: $activeSheet, onDismiss: {
            if let pending = pendingSheet {
                pendingSheet = nil
                activeSheet = pending
            }
        }) { sheet in
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
                            pendingSheet = .progressLog(exercise)
                        },
                        onStartSession: {
                            activeSheet = nil
                            pendingSheet = .session(exercise)
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fertig") { activeSheet = nil }
                        }
                    }
                }
            case .session(let exercise):
                ExerciseSessionView(
                    exercise: exercise,
                    maxPainLevel: maxPainLevel,
                    showSymptomResponse: appState.isNeck,
                    onComplete: {
                        exerciseVM?.markCompleted(exercise.id)
                        onExerciseLogged?()
                    }
                )
            case .customProgressLog(let exercise):
                CustomExerciseLogSheet(
                    exercise: exercise,
                    onSuccess: {
                        exerciseVM?.markCustomExerciseCompleted(exercise)
                        onExerciseLogged?()
                    }
                )
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

struct TendinopathyProfileQuickCard: View {
    let tendinopathyType: TendinopathyType
    let currentPhase: Int
    let maxPhase: Int

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous)
                .fill(Color.accent)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: tendinopathyIcon)
                        .font(.appBody)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Diagnose")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                Text(tendinopathyType.displayName)
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.textPrimary)
            }

            Spacer()

            Text("Phase \(currentPhase)/\(maxPhase)")
                .font(.appCaptionMedium)
                .foregroundStyle(.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
        }
        .accentCardStyle(color: .accent)
    }

    private var tendinopathyIcon: String {
        switch tendinopathyType {
        case .achilles, .patellar, .gluteal, .proximalHamstring, .plantarFascia:
            "figure.walk"
        case .tennisElbow, .golfersElbow, .rotatorCuff:
            "hand.raised"
        default:
            "figure.strengthtraining.traditional"
        }
    }
}
