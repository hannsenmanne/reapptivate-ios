import SwiftUI

// MARK: - Environment Key

private struct HapticsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var hapticsEnabled: Bool {
        get { self[HapticsEnabledKey.self] }
        set { self[HapticsEnabledKey.self] = newValue }
    }
}

// MARK: - Conditional Haptic Modifier

struct ConditionalHapticModifier<T: Equatable>: ViewModifier {
    @Environment(\.hapticsEnabled) private var hapticsEnabled
    let feedback: SensoryFeedback
    let trigger: T

    func body(content: Content) -> some View {
        content.sensoryFeedback(feedback, trigger: trigger) { _, _ in
            hapticsEnabled
        }
    }
}

extension View {
    func conditionalHaptic<T: Equatable>(_ feedback: SensoryFeedback, trigger: T) -> some View {
        modifier(ConditionalHapticModifier(feedback: feedback, trigger: trigger))
    }
}
