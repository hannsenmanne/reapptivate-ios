import SwiftUI

struct NeckShoulderScreeningView: View {
    @Environment(AppState.self) private var appState
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    var isEmbedded = false
    @State private var viewModel: NeckShoulderScreeningViewModel?
    @State private var showResult = false
    @State private var refreshError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.isLoading {
                        LoadingView(message: "Screening laden...")
                    } else if showResult, let result = vm.result {
                        NeckShoulderResultView(result: result) {
                            if isEmbedded {
                                Task { await refreshProfile() }
                            } else {
                                dismiss()
                            }
                        }
                    } else if vm.showSectionTransition {
                        SectionTransitionView(
                            title: vm.transitionTitle,
                            description: vm.transitionDescription
                        ) {
                            vm.continueToNextSection()
                        }
                    } else if let item = vm.currentItem {
                        VStack(spacing: 0) {
                            // Progress bar
                            ProgressView(value: vm.progress)
                                .tint(.accent)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                            HStack {
                                Text(vm.currentSection.title)
                                    .font(.appCaptionMedium)
                                    .foregroundStyle(.accent)
                                Spacer()
                                Text("\(vm.currentItemIndex + 1) von \(vm.currentItems.count)")
                                    .font(.appCaption)
                                    .foregroundStyle(.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                            // Question
                            NeckShoulderQuestionView(
                                item: item,
                                response: vm.responses[item.id],
                                onYesNo: { value in
                                    vm.selectYesNo(itemId: item.id, value: value)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                },
                                onScale: { value in
                                    vm.selectScale(itemId: item.id, value: value)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                },
                                onChoice: { value in
                                    vm.selectChoice(itemId: item.id, value: value)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                            .id(item.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))

                            Spacer()

                            // Submit button
                            if vm.canSubmit {
                                Button {
                                    Task {
                                        if await vm.submit() {
                                            withAnimation { showResult = true }
                                        }
                                    }
                                } label: {
                                    Group {
                                        if vm.isSubmitting {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Auswertung anzeigen")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                }
                                .buttonStyle(.accentFilled)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                        }
                    } else if let error = vm.errorMessage {
                        ErrorView(message: error) {
                            await vm.loadConfig()
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            .background(Color.appBg)
            .navigationTitle("Screening")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let vm = viewModel, vm.canGoBack && !showResult {
                        Button {
                            vm.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
            .interactiveDismissDisabled()
            .alert("Fehler", isPresented: Binding(
                get: { refreshError != nil },
                set: { if !$0 { refreshError = nil } }
            )) {
                Button("Erneut versuchen") {
                    Task { await refreshProfile() }
                }
            } message: {
                Text(refreshError ?? "")
            }
        }
        .task {
            let vm = NeckShoulderScreeningViewModel(apiClient: apiClient)
            viewModel = vm
            await vm.loadConfig()
        }
    }

    private func refreshProfile() async {
        do {
            let response: UserResponse = try await apiClient.request(APIEndpoints.me())
            appState.handleLogin(user: response.user)
        } catch {
            refreshError = "Profil konnte nicht aktualisiert werden. Bitte versuchen Sie es erneut."
        }
    }
}

// MARK: - Section Transition

struct SectionTransitionView: View {
    let title: String
    let description: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.painGreen)

            Text("Abschnitt abgeschlossen!")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)

                Text(description)
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                onContinue()
            } label: {
                Text("Weiter")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.accentFilled)
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Question View

struct NeckShoulderQuestionView: View {
    let item: NeckShoulderScreeningItem
    let response: AnyCodable?
    let onYesNo: (Bool) -> Void
    let onScale: (Int) -> Void
    let onChoice: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Question text
            Text(item.textDe)
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 32)

            // Input based on type
            switch item.type {
            case "yesno":
                yesNoInput
            case "scale":
                scaleInput
            case "choice":
                choiceInput
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Yes/No Input

    var yesNoInput: some View {
        HStack(spacing: 12) {
            OptionButton(
                label: "Ja",
                isSelected: responseAsBool == true,
                action: { onYesNo(true) }
            )
            OptionButton(
                label: "Nein",
                isSelected: responseAsBool == false,
                action: { onYesNo(false) }
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Scale Input (0-10)

    var scaleInput: some View {
        VStack(spacing: 16) {
            // Display current value
            Text("\(responseAsInt ?? 0)")
                .font(.appLargeTitle)
                .foregroundStyle(scaleColor(for: responseAsInt ?? 0))
                .frame(height: 60)

            // Slider
            Slider(
                value: Binding(
                    get: { Double(responseAsInt ?? 0) },
                    set: { onScale(Int($0.rounded())) }
                ),
                in: Double(item.min ?? 0)...Double(item.max ?? 10),
                step: 1
            )
            .tint(.accent)
            .padding(.horizontal, 24)

            // Labels
            HStack {
                Text("Kein Schmerz")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
                Spacer()
                Text("Stärkster Schmerz")
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Choice Input

    var choiceInput: some View {
        VStack(spacing: 8) {
            if let options = item.options {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    Button {
                        onChoice(option.value)
                    } label: {
                        HStack(spacing: 12) {
                            Text(option.labelDe)
                                .font(.appSubheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if responseAsString == option.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(responseAsString == option.value ? Color.accent.opacity(0.08) : Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous)
                                .stroke(
                                    responseAsString == option.value ? Color.accent : Color.gray200,
                                    lineWidth: responseAsString == option.value ? 1.5 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.textPrimary)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Response Accessors

    private var responseAsBool: Bool? {
        guard let response else { return nil }
        if let boolVal = response.value as? Bool { return boolVal }
        if let intVal = response.value as? Int { return intVal != 0 }
        return nil
    }

    private var responseAsInt: Int? {
        guard let response else { return nil }
        if let intVal = response.value as? Int { return intVal }
        if let doubleVal = response.value as? Double { return Int(doubleVal) }
        return nil
    }

    private var responseAsString: String? {
        guard let response else { return nil }
        return response.value as? String
    }

    private func scaleColor(for value: Int) -> Color {
        if value <= 3 { return .painGreen }
        if value <= 5 { return .painAmber }
        return .painRed
    }
}

// MARK: - Result View

struct NeckShoulderResultView: View {
    let result: NeckShoulderScreeningResult
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Severity badge
                VStack(spacing: 12) {
                    Circle()
                        .fill(severityColor)
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image(systemName: severityIcon)
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }

                    Text(result.severity.displayName)
                        .font(.appHeadline)
                        .foregroundStyle(severityColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(severityColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
                }
                .padding(.top, 32)

                // Red flag warning
                if result.redFlagAlert {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.painRed)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ärztliche Abklärung empfohlen")
                                .font(.appSubheadlineSemibold)
                                .foregroundStyle(.textPrimary)
                            Text("Ihre Antworten deuten auf Symptome hin, die ärztlich abgeklärt werden sollten. Bitte sprechen Sie mit Ihrem Therapeuten.")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                    .infoBoxStyle(color: .painRed)
                }

                // Scores
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ihre Ergebnisse")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    ScoreRow(label: "Schmerz", value: String(format: "%.1f/10", result.painScore))
                    ScoreRow(label: "Einschränkung", value: String(format: "%.1f/10", result.disabilityScore))

                    if let screenHours = result.screenHours {
                        ScoreRow(label: "Bildschirmzeit", value: "\(screenHours) Std./Tag")
                    }

                    if let stress = result.stressScore {
                        ScoreRow(label: "Stresslevel", value: String(format: "%.1f/10", stress))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Severity description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ihr Programm")
                        .font(.appHeadline)
                        .foregroundStyle(.textPrimary)

                    Text(severityDescription)
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text("Weiter zum Dashboard")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.accentFilled)
            }
            .padding(24)
        }
        .background(Color.appBg)
    }

    private var severityColor: Color {
        switch result.severity {
        case .mild: .painGreen
        case .moderate: .painAmber
        case .high: .painRed
        }
    }

    private var severityIcon: String {
        switch result.severity {
        case .mild: "checkmark"
        case .moderate: "exclamationmark"
        case .high: "exclamationmark.triangle"
        }
    }

    private var severityDescription: String {
        switch result.severity {
        case .mild:
            "Leichte Beschwerden. Ihr Programm umfasst 2x Krafttraining und tägliche Mobilität mit Mikro-Pausen."
        case .moderate:
            "Mittlere Beschwerden. Ihr Programm startet moderat mit 2-3x Krafttraining und regelmäßigen Pausen am Arbeitsplatz."
        case .high:
            "Deutliche Beschwerden. Ihr Programm beginnt sanft mit reduzierter Intensität und häufigeren Pausen."
        }
    }
}

// MARK: - Score Row

private struct ScoreRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.appSubheadlineSemibold)
                .foregroundStyle(.textPrimary)
        }
    }
}
