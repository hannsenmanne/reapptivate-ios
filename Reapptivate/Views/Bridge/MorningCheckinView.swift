import SwiftUI

struct MorningCheckinView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(AppState.self) private var appState
    @State private var viewModel: MorningCheckinViewModel?
    @State private var hapticTrigger = false

    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.accent)
                        .accessibilityHidden(true)

                    Text("Guten Morgen!")
                        .font(.appTitle)
                        .foregroundStyle(.textPrimary)

                    Text("Wie geht es dir heute?")
                        .font(.appBody)
                        .foregroundStyle(.textSecondary)
                }
                .padding(.top, 32)

                if let vm = viewModel {
                    // Pain Level (required)
                    painSection(vm)

                    // Sleep Quality (optional)
                    sleepSection(vm)

                    // Stiffness (optional)
                    stiffnessSection(vm)

                    // Mood (optional)
                    moodSection(vm)

                    // Notes (optional)
                    notesSection(vm)

                    // Error
                    if let error = vm.errorMessage {
                        InlineErrorView(message: error, onRetry: {
                            Task { await submitCheckin() }
                        })
                    }

                    // Submit
                    Button {
                        Task { await submitCheckin() }
                    } label: {
                        HStack {
                            if vm.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Check-In abschließen")
                                .font(.appHeadline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.primary)
                    .disabled(vm.isSubmitting)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.appBg)
        .interactiveDismissDisabled()
        .sensoryFeedback(.success, trigger: hapticTrigger)
        .task {
            if viewModel == nil {
                viewModel = MorningCheckinViewModel(apiClient: apiClient, appState: appState)
            }
        }
    }

    // MARK: - Sections

    private func painSection(_ vm: MorningCheckinViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Schmerzniveau")
                    .font(.appHeadline)
                    .foregroundStyle(.textPrimary)
                Text("*")
                    .foregroundStyle(.red)
            }

            HStack {
                Text("0")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)

                Slider(value: Binding(
                    get: { Double(vm.painLevel) },
                    set: { vm.painLevel = Int($0) }
                ), in: 0...10, step: 1)
                .tint(Color.painColor(for: vm.painLevel))

                Text("10")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            HStack {
                Spacer()
                Text("\(vm.painLevel)")
                    .font(.appTitle2)
                    .foregroundStyle(Color.painColor(for: vm.painLevel))
                    .contentTransition(.numericText())
                Spacer()
            }
        }
        .cardStyle()
    }

    private func sleepSection(_ vm: MorningCheckinViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schlafqualität")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        vm.sleepQuality = vm.sleepQuality == star ? nil : star
                    } label: {
                        Image(systemName: (vm.sleepQuality ?? 0) >= star ? "star.fill" : "star")
                            .font(.appTitle2)
                            .foregroundStyle((vm.sleepQuality ?? 0) >= star ? .yellow : .textSecondary.opacity(0.4))
                    }
                    .accessibilityLabel("\(star) Sterne")
                    .accessibilityAddTraits((vm.sleepQuality ?? 0) >= star ? .isSelected : [])
                }
                Spacer()
            }
        }
        .cardStyle()
    }

    private func stiffnessSection(_ vm: MorningCheckinViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steifheit")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            HStack {
                Text("0")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)

                Slider(value: Binding(
                    get: { Double(vm.stiffnessLevel ?? 0) },
                    set: { vm.stiffnessLevel = Int($0) == 0 ? nil : Int($0) }
                ), in: 0...10, step: 1)
                .tint(.accent)

                Text("10")
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
            }

            if let stiffness = vm.stiffnessLevel {
                HStack {
                    Spacer()
                    Text("\(stiffness)")
                        .font(.appTitle2)
                        .foregroundStyle(.accent)
                        .contentTransition(.numericText())
                    Spacer()
                }
            }
        }
        .cardStyle()
    }

    private func moodSection(_ vm: MorningCheckinViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stimmung")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            HStack(spacing: 12) {
                ForEach(Array(moodEmojis.enumerated()), id: \.offset) { index, emoji in
                    let value = index + 1
                    Button {
                        vm.mood = vm.mood == value ? nil : value
                    } label: {
                        Text(emoji)
                            .font(.system(size: 32))
                            .opacity(vm.mood == value ? 1 : 0.4)
                            .scaleEffect(vm.mood == value ? 1.15 : 1.0)
                            .animation(.spring(duration: 0.2), value: vm.mood)
                    }
                    .accessibilityLabel(moodLabels[index])
                    .accessibilityAddTraits(vm.mood == value ? .isSelected : [])
                }
                Spacer()
            }
        }
        .cardStyle()
    }

    private func notesSection(_ vm: MorningCheckinViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notizen")
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            TextField("Wie fühlst du dich heute?", text: Binding(
                get: { vm.notes },
                set: { vm.notes = $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
            .inputFieldStyle()
        }
        .cardStyle()
    }

    // MARK: - Actions

    private func submitCheckin() async {
        guard let vm = viewModel else { return }
        let success = await vm.submitCheckin()
        if success {
            hapticTrigger.toggle()
            onComplete()
        }
    }

    // MARK: - Constants

    private let moodEmojis = ["😫", "😕", "😐", "🙂", "😊"]
    private let moodLabels = ["Sehr schlecht", "Schlecht", "Neutral", "Gut", "Sehr gut"]
}
