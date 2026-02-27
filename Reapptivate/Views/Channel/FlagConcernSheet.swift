import SwiftUI

struct FlagConcernSheet: View {
    let viewModel: MessagingViewModel
    var exerciseId: String? = nil
    var exerciseName: String? = nil
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var step = 1
    @State private var selectedCategory: String?
    @State private var selectedSeverity: String?
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var hapticTrigger = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Step Indicator
                stepIndicator

                switch step {
                case 1:
                    categoryStep
                case 2:
                    severityStep
                case 3:
                    descriptionStep
                default:
                    EmptyView()
                }

                Spacer()
            }
            .padding(16)
            .background(Color.appBg)
            .navigationTitle(exerciseName != nil ? "Frage zu Übung" : "Bedenken melden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .sensoryFeedback(.selection, trigger: step)
            .sensoryFeedback(.success, trigger: hapticTrigger)
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { s in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(s <= step ? Color.accent : Color.textSecondary.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step 1: Category

    private var categoryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Was bereitet dir Sorgen?")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            ForEach(categories, id: \.key) { category in
                Button {
                    selectedCategory = category.key
                    withAnimation { step = 2 }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.appTitle3)
                            .foregroundStyle(category.color)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.label)
                                .font(.appSubheadlineSemibold)
                                .foregroundStyle(.textPrimary)
                            Text(category.description)
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Step 2: Severity

    private var severityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wie stark ist es?")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            ForEach(severities, id: \.key) { severity in
                Button {
                    selectedSeverity = severity.key
                    withAnimation { step = 3 }
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(severity.color)
                            .frame(width: 12, height: 12)

                        Text(severity.label)
                            .font(.appSubheadlineSemibold)
                            .foregroundStyle(.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.appCaption)
                            .foregroundStyle(.textSecondary)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Zurück")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
            }
        }
    }

    // MARK: - Step 3: Description

    private var descriptionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Beschreibe dein Anliegen")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            TextField("Was genau ist passiert? Wann tritt es auf?", text: $description, axis: .vertical)
                .lineLimit(4...8)
                .inputFieldStyle()

            Button {
                Task { await submitConcern() }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Absenden")
                        .font(.appHeadline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.primary)
            .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)

            Button {
                withAnimation { step = 2 }
            } label: {
                Text("Zurück")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
            }
        }
    }

    // MARK: - Submit

    private func submitConcern() async {
        isSubmitting = true

        let threadType = exerciseId != nil ? "exercise_question" : "flag_concern"
        let subject = exerciseName != nil ? "Frage zu: \(exerciseName!)" : categoryLabel

        let context = ThreadContext(
            category: selectedCategory,
            severity: selectedSeverity,
            exerciseId: exerciseId,
            exerciseName: exerciseName
        )

        let request = CreateThreadRequest(
            threadType: threadType,
            subject: subject,
            message: description,
            context: context
        )

        if let _ = await viewModel.createThread(request) {
            hapticTrigger.toggle()
            isSubmitting = false
            onComplete?()
            dismiss()
        } else {
            isSubmitting = false
        }
    }

    private var categoryLabel: String {
        categories.first { $0.key == selectedCategory }?.label ?? "Bedenken"
    }

    // MARK: - Data

    private struct CategoryOption {
        let key: String
        let label: String
        let description: String
        let icon: String
        let color: Color
    }

    private struct SeverityOption {
        let key: String
        let label: String
        let color: Color
    }

    private let categories: [CategoryOption] = [
        .init(key: "pain", label: "Schmerzen", description: "Neue oder verstärkte Schmerzen", icon: "bolt.fill", color: .painRed),
        .init(key: "swelling", label: "Schwellung", description: "Sichtbare Schwellung oder Erwärmung", icon: "drop.fill", color: .farBlue),
        .init(key: "stiffness", label: "Steifheit", description: "Eingeschränkte Beweglichkeit", icon: "figure.walk", color: .painAmber),
        .init(key: "uncertainty", label: "Unsicherheit", description: "Unsicher bei einer Übung oder Symptom", icon: "questionmark.circle.fill", color: .textSecondary),
    ]

    private let severities: [SeverityOption] = [
        .init(key: "low", label: "Leicht", color: .painGreen),
        .init(key: "medium", label: "Mittel", color: .painAmber),
        .init(key: "high", label: "Stark", color: .painRed),
    ]
}
