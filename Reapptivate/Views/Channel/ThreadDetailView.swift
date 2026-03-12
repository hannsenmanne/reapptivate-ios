import SwiftUI

struct ThreadDetailView: View {
    let threadId: String
    let viewModel: MessagingViewModel
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var messageText = ""
    @State private var hapticTrigger = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        let isEn = appLanguage == "en"

        VStack(spacing: 0) {
            // Status Badge
            if let thread = viewModel.currentThread {
                threadStatusBar(thread, isEn: isEn)
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    if viewModel.isLoadingMessages && viewModel.currentMessages.isEmpty {
                        ProgressView(isEn ? "Loading messages..." : "Nachrichten laden...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if viewModel.currentMessages.isEmpty {
                        EmptyStateView(
                            icon: "bubble.left.and.bubble.right",
                            title: isEn ? "No messages yet" : "Noch keine Nachrichten",
                            message: isEn ? "Send the first message." : "Sende die erste Nachricht."
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.currentMessages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .onChange(of: viewModel.currentMessages.count) { _, _ in
                    if let lastId = viewModel.currentMessages.last?.id {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            // Reply Bar
            replyBar(isEn: isEn)
        }
        .background(Color.appBg)
        .navigationTitle(viewModel.currentThread?.subject ?? (isEn ? "Message" : "Nachricht"))
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: hapticTrigger)
        .task {
            await viewModel.fetchThreadDetail(threadId)
            viewModel.startMessagePolling(threadId: threadId)
        }
        .onDisappear {
            viewModel.stopMessagePolling()
        }
    }

    // MARK: - Status Bar

    private func threadStatusBar(_ thread: ClinicalThread, isEn: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: thread.threadTypeIcon)
                .font(.appCaption)

            Text(threadTypeLabel(for: thread, isEn: isEn))
                .font(.appCaptionMedium)

            Spacer()

            Text(thread.isOpen
                ? (isEn ? "Open" : "Offen")
                : (isEn ? "Resolved" : "Gelöst"))
                .font(.appCaptionBold)
                .foregroundStyle(thread.isOpen ? .painAmber : .painGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background((thread.isOpen ? Color.painAmber : Color.painGreen).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.badgeRadius, style: .continuous))
        }
        .foregroundStyle(.textSecondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.cardBg)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Reply Bar

    private func replyBar(isEn: Bool) -> some View {
        HStack(spacing: 12) {
            TextField(isEn ? "Write a message..." : "Nachricht schreiben...", text: $messageText, axis: .vertical)
                .lineLimit(1...4)
                .inputFieldStyle()
                .focused($isTextFieldFocused)

            Button {
                Task { await sendMessage() }
            } label: {
                if viewModel.isSending {
                    ProgressView()
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .textSecondary.opacity(0.4) : .accent)
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            .accessibilityLabel(isEn ? "Send" : "Senden")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.cardBg)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: - Actions

    private func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let success = await viewModel.sendMessage(threadId: threadId, content: text)
        if success {
            messageText = ""
            hapticTrigger.toggle()
            isTextFieldFocused = false
        }
    }

    private func threadTypeLabel(for thread: ClinicalThread, isEn: Bool) -> String {
        switch thread.threadType {
        case "flag_concern": return isEn ? "Concern" : "Bedenken"
        case "exercise_question": return isEn ? "Question" : "Frage"
        case "progress_share": return isEn ? "Progress" : "Fortschritt"
        case "free_text": return isEn ? "Message" : "Nachricht"
        default: return thread.threadType
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ClinicalMessage

    var body: some View {
        if message.isSystem {
            // System message: centered, italic
            Text(message.content)
                .font(.appCaption)
                .italic()
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
        } else {
            HStack {
                if message.isFromPatient { Spacer(minLength: 48) }

                VStack(alignment: message.isFromPatient ? .trailing : .leading, spacing: 4) {
                    Text(message.content)
                        .font(.appBody)
                        .foregroundStyle(message.isFromPatient ? .white : .textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(bubbleBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(DateFormatters.timeOnly.string(from: message.createdAt))
                        .font(.appCaption2)
                        .foregroundStyle(.textSecondary)
                }

                if message.isFromTherapist { Spacer(minLength: 48) }
            }
        }
    }

    private var bubbleBackground: some ShapeStyle {
        if message.isFromPatient {
            return AnyShapeStyle(Color.accent)
        } else {
            return AnyShapeStyle(Color.gray200)
        }
    }
}
