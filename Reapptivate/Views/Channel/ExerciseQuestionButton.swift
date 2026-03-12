import SwiftUI

struct ExerciseQuestionButton: View {
    let exerciseId: String
    let exerciseName: String
    @Environment(APIClient.self) private var apiClient
    @Environment(AppState.self) private var appState
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var showConcernSheet = false
    @State private var messagingVM: MessagingViewModel?

    var body: some View {
        Button {
            showConcernSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.appCaption)
                Text(appLanguage == "en" ? "Ask a question" : "Frage stellen")
                    .font(.appCaptionMedium)
            }
            .foregroundStyle(.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appLanguage == "en" ? "Ask a question about \(exerciseName)" : "Frage zu \(exerciseName) stellen")
        .sheet(isPresented: $showConcernSheet) {
            if let vm = messagingVM {
                FlagConcernSheet(
                    viewModel: vm,
                    exerciseId: exerciseId,
                    exerciseName: exerciseName
                )
            }
        }
        .task {
            if messagingVM == nil {
                messagingVM = MessagingViewModel(apiClient: apiClient, appState: appState)
            }
        }
    }
}
