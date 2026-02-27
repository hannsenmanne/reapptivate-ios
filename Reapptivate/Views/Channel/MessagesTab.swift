import SwiftUI

struct MessagesTab: View {
    let viewModel: MessagingViewModel

    var body: some View {
        NavigationStack {
            ThreadListView(viewModel: viewModel)
                .navigationDestination(for: String.self) { threadId in
                    ThreadDetailView(threadId: threadId, viewModel: viewModel)
                }
                .navigationTitle("Nachrichten")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
