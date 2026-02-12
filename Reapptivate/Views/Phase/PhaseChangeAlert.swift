import SwiftUI

struct PhaseChangeAlert: View {
    let result: AdaptationResult
    let phaseName: String
    let onDismiss: () -> Void

    @State private var isVisible = false

    var isProgress: Bool { result.decision == .progress }

    var body: some View {
        if isVisible {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: isProgress ? "arrow.up.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(isProgress ? .painGreen : .painAmber)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isProgress ? "Phase aufgestiegen!" : "Phase angepasst")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(phaseName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            isVisible = false
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(16)
                .background(isProgress ? Color(hex: "1F2937") : Color.painAmber)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
