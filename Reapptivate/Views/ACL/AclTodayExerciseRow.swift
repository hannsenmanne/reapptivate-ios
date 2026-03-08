import SwiftUI

struct AclTodayExerciseRow: View {
    let exercise: AclStreamExercise
    let index: Int
    let isCompleted: Bool
    let isSubmitting: Bool
    let userGraftType: String?
    let userConcomitantInjuries: Set<String>
    let onToggle: () -> Void
    var onTap: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(alignment: .top, spacing: 12) {
                Text(String(format: "%02d", index + 1))
                    .font(.appCaptionMedium)
                    .foregroundStyle(isCompleted ? .textSecondary.opacity(0.5) : .textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        onTap?()
                    } label: {
                        HStack(spacing: 8) {
                            Text(exercise.nameDE ?? exercise.name)
                                .font(.appSubheadlineSemibold)
                                .foregroundStyle(isCompleted ? .textSecondary.opacity(0.6) : .textPrimary)
                                .strikethrough(isCompleted, color: .textSecondary)
                                .multilineTextAlignment(.leading)

                            if isCompleted {
                                Text("Erledigt")
                                    .font(.appCaption2)
                                    .foregroundStyle(.painGreen)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.painGreen.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.appCaption2)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    parameterBadges
                        .opacity(isCompleted ? 0.5 : 1.0)

                    if isExpanded {
                        expandedContent
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()

                // Toggle button
                Button(action: onToggle) {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundStyle(isCompleted ? .painGreen : .textSecondary)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
                .accessibilityLabel(isCompleted ? "Als unerledigt markieren" : "Als erledigt markieren")
                .accessibilityHint(exercise.nameDE ?? exercise.name)
            }

            // Expand toggle
            if hasExpandableContent {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.appCaption2)
                        Text(isExpanded ? "Weniger anzeigen" : "Details anzeigen")
                            .font(.appCaption)
                    }
                    .foregroundStyle(.textSecondary)
                    .padding(.leading, 36)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Details einklappen" : "Details ausklappen")
            }
        }
        .padding(.vertical, 4)
        .cardStyle()
        .opacity(isCompleted ? 0.85 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }

    // MARK: - Expandable Content

    private var hasExpandableContent: Bool {
        (exercise.descriptionDE ?? exercise.description) != nil
        || hasGraftNote
        || hasPrecaution
    }

    private var hasGraftNote: Bool {
        if let note = exercise.graftNote, !note.isEmpty { return true }
        guard let graftModifier = exercise.graftModifier,
              let graft = userGraftType,
              let note = graftModifier[graft] else { return false }
        return !note.isEmpty
    }

    private var hasPrecaution: Bool {
        if let notes = exercise.precautions, !notes.isEmpty { return true }
        guard let precaution = exercise.concomitantPrecaution else { return false }
        return precaution.contains { userConcomitantInjuries.contains($0.key) && !$0.value.isEmpty }
    }

    /// Prefer enriched flat field, fall back to dictionary lookup
    private var resolvedGraftNote: String? {
        if let note = exercise.graftNote, !note.isEmpty { return note }
        guard let graftModifier = exercise.graftModifier,
              let graft = userGraftType,
              let note = graftModifier[graft], !note.isEmpty else { return nil }
        return note
    }

    /// Prefer enriched flat field, fall back to dictionary lookup
    private var resolvedPrecautions: String? {
        if let notes = exercise.precautions, !notes.isEmpty { return notes }
        guard let precaution = exercise.concomitantPrecaution else { return nil }
        let relevant = precaution.filter { userConcomitantInjuries.contains($0.key) }
        let notes = relevant.values.filter { !$0.isEmpty }.joined(separator: ". ")
        return notes.isEmpty ? nil : notes
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let desc = exercise.descriptionDE ?? exercise.description {
                Text(desc)
                    .font(.appCaption)
                    .foregroundStyle(.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let note = resolvedGraftNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.appCaption)
                        .foregroundStyle(.farBlue)
                    Text(note)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .infoBoxStyle(color: .farBlue)
            }

            if let notes = resolvedPrecautions {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.appCaption)
                        .foregroundStyle(.painAmber)
                    Text(notes)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
                .infoBoxStyle(color: .painAmber)
            }
        }
        .padding(.leading, 36)
        .padding(.top, 4)
    }

    // MARK: - Parameter Badges

    @ViewBuilder
    private var parameterBadges: some View {
        let params = buildParams()
        if !params.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(params, id: \.label) { param in
                    Text(param.label)
                        .font(.appCaption2)
                        .foregroundStyle(param.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(param.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
        }
    }

    private struct ParamTag {
        let label: String
        let color: Color
    }

    private func buildParams() -> [ParamTag] {
        var tags: [ParamTag] = []
        if let sets = exercise.sets {
            tags.append(ParamTag(label: "\(sets) Sätze", color: .farBlue))
        }
        if let reps = exercise.reps {
            tags.append(ParamTag(label: "\(reps)x Wdh.", color: .accent))
        }
        if let hold = exercise.holdTime, hold > 0 {
            tags.append(ParamTag(label: "\(hold)s Halten", color: .phaseInitial))
        }
        if let tempo = exercise.tempo {
            tags.append(ParamTag(label: "Tempo \(tempo)", color: .painAmber))
        }
        return tags
    }
}
