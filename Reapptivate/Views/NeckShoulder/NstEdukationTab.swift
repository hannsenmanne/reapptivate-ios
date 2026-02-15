import SwiftUI

/// Edukation tab for neck-shoulder tension patients.
/// Shows NST micro-modules and general Wissen cards.
struct NstEdukationTab: View {
    @Environment(AppState.self) private var appState
    let severity: NeckShoulderSeverity

    var body: some View {
        VStack(spacing: 20) {
            // NST-specific micro-modules
            NstMicroModulesView(severity: severity)

            // General Wissen cards
            if let user = appState.currentUser {
                WissenAllCardsView(phase: user.currentPhase, isLbp: false, isNeck: false)
            }
        }
        .padding(.bottom, 32)
    }
}
