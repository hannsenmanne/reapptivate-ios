import SwiftUI

struct WorkTimerBreakView: View {
    @Bindable var viewModel: WorkTimerViewModel
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .title) private var ringSize: CGFloat = 100
    @State private var completeTrigger = false
    @State private var isLogging = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.cooldown")
                            .font(.system(size: 40))
                            .foregroundStyle(.accent)
                            .accessibilityHidden(true)

                        Text("Bewegungspause!")
                            .font(.appTitle2)
                            .foregroundStyle(.textPrimary)

                        Text("Pause \(viewModel.currentBreakNumber)")
                            .font(.appSubheadlineMedium)
                            .foregroundStyle(.textSecondary)
                    }
                    .padding(.top, 8)

                    // Countdown ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray200, lineWidth: 8)
                            .frame(width: ringSize, height: ringSize)

                        Circle()
                            .trim(from: 0, to: viewModel.breakProgress)
                            .stroke(Color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: ringSize, height: ringSize)
                            .animation(.linear(duration: 1), value: viewModel.breakProgress)

                        Text(viewModel.formattedBreakTimeRemaining)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundStyle(.textPrimary)
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Verbleibende Pausenzeit: \(viewModel.formattedBreakTimeRemaining)")

                    // Exercise cards
                    if !viewModel.breakExercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Übungen")
                                .font(.appHeadline)
                                .foregroundStyle(.textPrimary)

                            ForEach(viewModel.breakExercises) { exercise in
                                BreakExerciseCard(exercise: exercise)
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            isLogging = true
                            Task {
                                await viewModel.completeBreak()
                                completeTrigger.toggle()
                                isLogging = false
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                Text("Pause abgeschlossen")
                            }
                        }
                        .buttonStyle(.accentFilled)
                        .disabled(isLogging)

                        Button {
                            isLogging = true
                            Task {
                                await viewModel.skipBreak()
                                isLogging = false
                                dismiss()
                            }
                        } label: {
                            Text("Überspringen")
                                .font(.appSubheadlineMedium)
                                .foregroundStyle(.textSecondary)
                        }
                        .disabled(isLogging)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.appBg)
            .navigationBarTitleDisplayMode(.inline)
        }
        .conditionalHaptic(.success, trigger: completeTrigger)
    }
}

// MARK: - Break Exercise Card

private struct BreakExerciseCard: View {
    let exercise: WorkTimerBreakExercise

    private var categoryIcon: String {
        switch exercise.category {
        case "mobility": return "figure.walk"
        case "stretch": return "figure.flexibility"
        case "breathing": return "wind"
        case "strength": return "figure.strengthtraining.traditional"
        default: return "figure.cooldown"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: categoryIcon)
                .font(.appBody)
                .foregroundStyle(.accent)
                .frame(width: 32, height: 32)
                .background(Color.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.appSubheadlineSemibold)
                    .foregroundStyle(.textPrimary)

                Text(exercise.description)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(exercise.durationSeconds) Sek.")
                    .font(.appCaption2)
                    .foregroundStyle(.textTertiary)
            }
        }
        .cardStyle()
    }
}
