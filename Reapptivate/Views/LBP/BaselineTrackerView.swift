import SwiftUI

struct BaselineTrackerView: View {
    @Bindable var viewModel: LbpEnhancementsViewModel
    @State private var selectedActivityKey: String?
    @State private var duration: Int = 15
    @State private var painLevel: Double = 3
    @State private var isSubmitting = false
    @State private var isCalculating = false

    var body: some View {
        VStack(spacing: 16) {
            // Header card
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title3)
                        .foregroundStyle(.farBlue)
                    Text("Baseline-Tracking Phase")
                        .font(.headline)
                        .foregroundStyle(.textPrimary)
                    Spacer()
                }

                // Progress
                let days = viewModel.baselineDaysLogged
                VStack(spacing: 6) {
                    HStack {
                        Text("Fortschritt: \(days)/5 Tage")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.textSecondary)
                        Spacer()
                        Text("\(min(100, days * 20))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.farBlue)
                    }

                    ProgressView(value: Double(min(days, 5)), total: 5)
                        .tint(.farBlue)
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.farBlue.opacity(0.1), Color.farBlue.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Logging form
            VStack(alignment: .leading, spacing: 16) {
                Text("Aktivitat loggen")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textPrimary)

                // Activity selector
                if let activities = viewModel.pacingPlan?.targetActivities {
                    VStack(spacing: 6) {
                        ForEach(activities) { activity in
                            Button {
                                selectedActivityKey = activity.key
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: selectedActivityKey == activity.key ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedActivityKey == activity.key ? .accent : .textSecondary)
                                    Text(activity.label)
                                        .font(.subheadline)
                                        .foregroundStyle(.textPrimary)
                                    Spacer()
                                }
                                .padding(10)
                                .background(selectedActivityKey == activity.key ? Color.accent.opacity(0.06) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Duration
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dauer (Minuten)")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)

                    HStack(spacing: 16) {
                        Button {
                            duration = max(5, duration - 5)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.textSecondary)
                        }

                        Text("\(duration)")
                            .font(.title2.weight(.bold).monospacedDigit())
                            .foregroundStyle(.textPrimary)
                            .frame(width: 50)

                        Button {
                            duration += 5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Pain level
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Schmerzniveau")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                        Spacer()
                        Text("\(Int(painLevel))/10")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.painColor(for: Int(painLevel)))
                    }

                    Slider(value: $painLevel, in: 0...10, step: 1)
                        .tint(Color.painColor(for: Int(painLevel)))
                }

                // Log button
                Button {
                    Task { await logActivity() }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Aktivitat loggen")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(selectedActivityKey != nil ? Color.farBlue : Color.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(selectedActivityKey == nil || isSubmitting)
            }
            .padding(16)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Logged entries
            if let logs = viewModel.pacingPlan?.baselineLogs, !logs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Protokollierte Aktivitaten")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.textPrimary)

                    let grouped = Dictionary(grouping: logs) { $0.date }
                    let sortedDays = grouped.keys.sorted(by: >)

                    ForEach(sortedDays, id: \.self) { date in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(date)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.textSecondary)

                            ForEach(grouped[date] ?? [], id: \.activityKey) { log in
                                HStack(spacing: 8) {
                                    Text(log.activityKey)
                                        .font(.caption)
                                        .foregroundStyle(.textPrimary)
                                    Spacer()
                                    Text("\(log.duration) Min")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.textSecondary)
                                    Text("Schmerz: \(log.painLevel)")
                                        .font(.caption)
                                        .foregroundStyle(Color.painColor(for: log.painLevel))
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.appBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(16)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Calculate button
            if viewModel.isBaselineReady {
                Button {
                    Task { await calculate() }
                } label: {
                    HStack(spacing: 8) {
                        if isCalculating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "function")
                            Text("Baseline berechnen & Quoten setzen")
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.painGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isCalculating)
            }
        }
    }

    // MARK: - Actions

    private func logActivity() async {
        guard let key = selectedActivityKey else { return }
        isSubmitting = true
        if await viewModel.logBaselineActivity(activityKey: key, duration: duration, painLevel: Int(painLevel)) {
            selectedActivityKey = nil
            duration = 15
            painLevel = 3
        }
        isSubmitting = false
    }

    private func calculate() async {
        isCalculating = true
        _ = await viewModel.calculateBaseline()
        isCalculating = false
    }
}
