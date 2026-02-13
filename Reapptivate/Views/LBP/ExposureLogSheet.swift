import SwiftUI

struct ExposureLogSheet: View {
    let item: FearHierarchyItem
    @Bindable var viewModel: LbpEnhancementsViewModel
    @Environment(\.dismiss) private var dismiss

    enum ExposureStep: Int, CaseIterable {
        case prepare, post, complete
    }

    @State private var step: ExposureStep = .prepare
    @State private var preFear: Double = 5
    @State private var postFear: Double = 3
    @State private var postPain: Double = 2
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var fearReduction: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator
                HStack(spacing: 8) {
                    ForEach(ExposureStep.allCases, id: \.rawValue) { s in
                        Circle()
                            .fill(s.rawValue <= step.rawValue ? Color.farBlue : Color.textSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        switch step {
                        case .prepare:
                            prepareStep
                        case .post:
                            postStep
                        case .complete:
                            completeStep
                        }
                    }
                    .padding(24)
                }

                // Action buttons
                if step != .complete {
                    VStack(spacing: 8) {
                        Button {
                            handleAction()
                        } label: {
                            Text(step == .prepare ? "Aktivität durchführen" : "Speichern")
                                .font(.appBodySemibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.farBlue)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.appBg)
            .navigationTitle("Verhaltensexperiment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") { dismiss() }
                }
            }
        }
    }

    // MARK: - Prepare Step

    private var prepareStep: some View {
        VStack(spacing: 20) {
            // Activity card
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .foregroundStyle(.farBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(.appSubheadlineMedium)
                        .foregroundStyle(.textPrimary)
                    Text("Ursprüngliche Angst: \(item.fearRating0To10)/10")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
            }
            .infoBoxStyle(color: .farBlue)

            // Pre-fear rating
            VStack(alignment: .leading, spacing: 8) {
                Text("Aktuelle Angst jetzt")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)

                HStack(spacing: 12) {
                    Slider(value: $preFear, in: 0...10, step: 1)
                        .tint(.farBlue)
                    Text("\(Int(preFear))")
                        .font(.appTitle3.monospacedDigit())
                        .foregroundStyle(.farBlue)
                        .frame(width: 28)
                }

                HStack {
                    Text("Keine Angst")
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                    Spacer()
                    Text("Maximale Angst")
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                }
            }

            // Encouragement
            VStack(spacing: 8) {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.appTitle2)
                    .foregroundStyle(.painGreen)
                Text("Bereit? Versuchen Sie jetzt die Aktivität durchzuführen.")
                    .font(.appSubheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .infoBoxStyle(color: .painGreen)
        }
    }

    // MARK: - Post Step

    private var postStep: some View {
        VStack(spacing: 20) {
            // Post-fear rating
            VStack(alignment: .leading, spacing: 8) {
                Text("Angst NACHHER")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)

                HStack(spacing: 12) {
                    Slider(value: $postFear, in: 0...10, step: 1)
                        .tint(.farBlue)
                    Text("\(Int(postFear))")
                        .font(.appTitle3.monospacedDigit())
                        .foregroundStyle(.farBlue)
                        .frame(width: 28)
                }
            }

            // Post-pain
            VStack(alignment: .leading, spacing: 8) {
                Text("Schmerz NACHHER")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)

                HStack(spacing: 12) {
                    Slider(value: $postPain, in: 0...10, step: 1)
                        .tint(Color.painColor(for: Int(postPain), maxPainLevel: 5))
                    Text("\(Int(postPain))")
                        .font(.appTitle3.monospacedDigit())
                        .foregroundStyle(Color.painColor(for: Int(postPain), maxPainLevel: 5))
                        .frame(width: 28)
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("Notizen (optional)")
                    .font(.appSubheadlineMedium)
                    .foregroundStyle(.textPrimary)

                TextEditor(text: $notes)
                    .font(.appSubheadline)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DesignTokens.inputRadius, style: .continuous).stroke(Color.gray200, lineWidth: 1))
            }
        }
    }

    // MARK: - Complete Step

    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.painGreen)

            Text("Super gemacht!")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            if fearReduction > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(.painGreen)
                    Text("Angst-Reduktion: -\(fearReduction) Punkte")
                        .font(.appHeadline)
                        .foregroundStyle(.painGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.painGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
            }

            Text("Jede Exposition hilft Ihrem Gehirn zu lernen, dass diese Aktivität sicher ist.")
                .font(.appSubheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Fertig")
                    .font(.appBodySemibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.farBlue)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius, style: .continuous))
            }
        }
        .padding(.top, 32)
    }

    // MARK: - Actions

    private func handleAction() {
        switch step {
        case .prepare:
            withAnimation { step = .post }
        case .post:
            Task { await submitExposure() }
        case .complete:
            break
        }
    }

    private func submitExposure() async {
        isSubmitting = true
        let fb = Int(preFear)
        let fa = Int(postFear)
        let pp = Int(postPain)
        fearReduction = fb - fa

        let request = ExposureLogRequest(
            predictedHarm: nil,
            predictedFear: nil,
            preFear: fb,
            prePain: 0,
            performedDose: nil,
            postFear: fa,
            postPain: pp,
            didAvoid: false,
            outcomeNotes: notes.isEmpty ? nil : notes
        )

        if await viewModel.logExposure(itemId: item.id, request: request) {
            withAnimation { step = .complete }
        }
        isSubmitting = false
    }
}
