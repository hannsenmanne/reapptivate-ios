import SwiftUI

struct CoachMarkView: View {
    let message: String
    let edge: Edge
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if edge == .bottom {
                triangle
                    .rotationEffect(.degrees(180))
            }

            Text(message)
                .font(.appCaption)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius, style: .continuous))

            if edge == .top {
                triangle
            }
        }
        .onTapGesture { onDismiss() }
        .transition(.scale.combined(with: .opacity))
    }

    private var triangle: some View {
        Triangle()
            .fill(Color.textPrimary)
            .frame(width: 14, height: 7)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

// MARK: - Coach Mark Modifier

struct CoachMarkModifier: ViewModifier {
    let key: String
    let message: String
    let edge: Edge

    @AppStorage private var hasSeen: Bool
    @State private var isVisible = false

    init(key: String, message: String, edge: Edge) {
        self.key = key
        self.message = message
        self.edge = edge
        self._hasSeen = AppStorage(wrappedValue: false, "coachmark_\(key)_seen")
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: edge == .top ? .top : .bottom) {
                if isVisible {
                    CoachMarkView(message: message, edge: edge) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isVisible = false
                        }
                        hasSeen = true
                    }
                    .offset(y: edge == .top ? -8 : 8)
                }
            }
            .task {
                if !hasSeen {
                    try? await Task.sleep(for: .milliseconds(800))
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    func coachMark(key: String, message: String, edge: Edge = .top) -> some View {
        modifier(CoachMarkModifier(key: key, message: message, edge: edge))
    }
}
