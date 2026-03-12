import SwiftUI

struct MessagesTab: View {
    let viewModel: MessagingViewModel
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        NavigationStack {
            ThreadListView(viewModel: viewModel)
                .navigationDestination(for: String.self) { threadId in
                    ThreadDetailView(threadId: threadId, viewModel: viewModel)
                }
                .navigationTitle(appLanguage == "en" ? "Messages" : "Nachrichten")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
