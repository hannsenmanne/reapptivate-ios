import SwiftUI

struct MessagesTab: View {
    let viewModel: MessagingViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        NavigationStack {
            ThreadListView(viewModel: viewModel)
                .navigationDestination(for: String.self) { threadId in
                    ThreadDetailView(threadId: threadId, viewModel: viewModel)
                }
                .navigationTitle(appLanguage == "en" ? "Messages" : "Nachrichten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.appBody)
                        }
                        .accessibilityLabel(appLanguage == "en" ? "Close" : "Schließen")
                    }
                }
        }
    }
}
