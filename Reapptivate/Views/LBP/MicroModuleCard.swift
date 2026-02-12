import SwiftUI

struct MicroModuleCard: View {
    let module: MicroModule
    let isCompleted: Bool
    let isMarking: Bool
    let onMarkRead: () -> Void

    @State private var isExpanded = false

    var moduleIcon: String {
        let key = module.key.lowercased()
        if key.contains("expectation") || key.contains("experiment") { return "magnifyingglass" }
        if key.contains("pacing") || key.contains("dosier") { return "timer" }
        if key.contains("distress") || key.contains("regulat") { return "brain.head.profile" }
        if key.contains("fear") || key.contains("angst") { return "eye" }
        if key.contains("pain") || key.contains("schmerz") { return "waveform.path.ecg" }
        return "book.fill"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: moduleIcon)
                        .font(.subheadline)
                        .foregroundStyle(.farBlue)
                        .frame(width: 32, height: 32)
                        .background(Color.farBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(module.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if isCompleted {
                        Text("Abgeschlossen")
                            .font(.caption2)
                            .foregroundStyle(.painGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.painGreen.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 16) {
                    // Body text
                    Text(module.content)
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                        .lineSpacing(4)

                    // Take-home message
                    if let takeHome = module.takeHome, !takeHome.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.painAmber)
                                .font(.subheadline)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Kernbotschaft")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.textPrimary)
                                Text(takeHome)
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                        .padding(12)
                        .background(Color.painAmber.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Mark as read button
                    if !isCompleted {
                        Button {
                            onMarkRead()
                        } label: {
                            HStack(spacing: 6) {
                                if isMarking {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark")
                                    Text("Gelesen")
                                }
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.painGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(isMarking)
                    }
                }
                .padding(14)
            }
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
