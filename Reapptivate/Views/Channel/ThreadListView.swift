import SwiftUI

struct ThreadListView: View {
    let viewModel: MessagingViewModel
    @State private var showNewMessageSheet = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.threads.isEmpty {
                ProgressView("Nachrichten laden...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if viewModel.threads.isEmpty {
                EmptyStateView(
                    icon: "message",
                    title: "Keine Nachrichten",
                    message: "Starte eine Konversation mit deinem Therapeuten."
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.threads) { thread in
                        NavigationLink(value: thread.id) {
                            ThreadRow(thread: thread)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }

            if let error = viewModel.errorMessage {
                InlineErrorView(message: error, onRetry: {
                    Task { await viewModel.fetchThreads() }
                })
                .padding(16)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewMessageSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.appBody)
                }
                .accessibilityLabel("Neue Nachricht")
            }
        }
        .sheet(isPresented: $showNewMessageSheet) {
            NewMessageSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchThreads()
        }
    }
}

// MARK: - Thread Row

private struct ThreadRow: View {
    let thread: ClinicalThread

    var body: some View {
        HStack(spacing: 12) {
            // Type Icon
            Image(systemName: thread.threadTypeIcon)
                .font(.appTitle3)
                .foregroundStyle(threadColor)
                .frame(width: 36, height: 36)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(thread.subject)
                        .font(.appSubheadlineSemibold)
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(formattedDate)
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                }

                if let lastMessage = thread.lastMessage {
                    Text(lastMessage)
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Text(thread.threadTypeLabel)
                        .font(.appCaption2)
                        .foregroundStyle(threadColor)

                    if thread.isResolved {
                        Text("Gelöst")
                            .font(.appCaption2)
                            .foregroundStyle(.painGreen)
                    }
                }
            }

            // Unread Badge
            if let unread = thread.unreadCount, unread > 0 {
                Text("\(unread)")
                    .font(.appCaptionBold)
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var threadColor: Color {
        switch thread.threadTypeColor {
        case "red": .painRed
        case "blue": .farBlue
        case "green": .painGreen
        default: .textSecondary
        }
    }

    private var formattedDate: String {
        let date = thread.lastMessageAt ?? thread.createdAt
        if Calendar.current.isDateInToday(date) {
            return DateFormatters.timeOnly.string(from: date)
        } else {
            return DateFormatters.dateOnly.string(from: date)
        }
    }
}

// MARK: - New Message Sheet

private struct NewMessageSheet: View {
    let viewModel: MessagingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showConcernFlow = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    showConcernFlow = true
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bedenken melden")
                                .font(.appBody)
                                .foregroundStyle(.textPrimary)
                            Text("Schmerzen, Schwellung oder Unsicherheit")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.painRed)
                    }
                }

                Button {
                    Task {
                        let request = CreateThreadRequest(
                            threadType: "progress_share",
                            subject: "Fortschritt teilen",
                            message: "",
                            context: nil
                        )
                        if let _ = await viewModel.createThread(request) {
                            dismiss()
                        }
                    }
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fortschritt teilen")
                                .font(.appBody)
                                .foregroundStyle(.textPrimary)
                            Text("Positive Entwicklung mitteilen")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.painGreen)
                    }
                }

                Button {
                    Task {
                        let request = CreateThreadRequest(
                            threadType: "free_text",
                            subject: "Nachricht",
                            message: "",
                            context: nil
                        )
                        if let _ = await viewModel.createThread(request) {
                            dismiss()
                        }
                    }
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Freitext")
                                .font(.appBody)
                                .foregroundStyle(.textPrimary)
                            Text("Allgemeine Nachricht senden")
                                .font(.appCaption)
                                .foregroundStyle(.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .navigationTitle("Neue Nachricht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .sheet(isPresented: $showConcernFlow) {
                FlagConcernSheet(viewModel: viewModel) {
                    dismiss()
                }
            }
        }
    }
}
