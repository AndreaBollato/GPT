import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var uiState: UIState
    let conversation: Conversation

    var onSearchTapped: () -> Void = {}

    @FocusState private var composerFocused: Bool

    private var draftBinding: Binding<String> {
        Binding(
            get: { uiState.draft(for: conversation.id) },
            set: { uiState.setDraft($0, for: conversation.id) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(
                title: conversation.title,
                status: TopBarView.Status(
                    text: uiState.isStreamingResponse ? "Risposta in corso" : "Pronto",
                    color: uiState.isStreamingResponse ? AppColors.accent : AppColors.subtleText
                ),
                selectedModelId: conversation.modelId,
                onSelectModel: { modelId in
                    uiState.updateModel(for: conversation.id, to: modelId)
                },
                onNewChat: uiState.beginNewChat,
                onSearch: onSearchTapped,
                onDuplicate: {
                    uiState.duplicateConversation(id: conversation.id)
                },
                onDelete: {
                    uiState.deleteConversation(id: conversation.id)
                },
                isStreaming: uiState.isStreamingResponse,
                onStopStreaming: uiState.stopStreaming
            )
            Divider()
            messages
            Divider()
            ComposerView(
                text: draftBinding,
                placeholder: "Invia un messaggio",
                isStreaming: uiState.isStreamingResponse,
                onSubmit: submitMessage,
                onStop: uiState.stopStreaming,
                focus: $composerFocused
            )
            .padding(.horizontal, AppConstants.Spacing.xl)
            .padding(.vertical, AppConstants.Spacing.lg)
            .background(AppColors.background)
        }
        .background(AppColors.background)
        .onAppear {
            composerFocused = true
        }
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    ForEach(conversation.messages) { message in
                        MessageRowView(message: message)
                            .id(message.id)
                    }

                    if uiState.isAssistantTyping {
                        MessageRowView(message: Message(role: .assistant, text: "", isLoading: true))
                            .id(UUID())
                    }
                }
                .padding(.vertical, AppConstants.Spacing.xl)
            }
            .background(AppColors.chatBackground)
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: conversation.messages.count) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: uiState.isAssistantTyping) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func submitMessage() {
        let currentDraft = draftBinding.wrappedValue
        let conversationID = uiState.submit(text: currentDraft, in: conversation.id)
        if conversationID != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                composerFocused = true
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastId = conversation.messages.last?.id else { return }
        let action = {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
        if animated {
            withAnimation(AppConstants.Animation.easeInOut) { action() }
        } else {
            action()
        }
    }
}

// struct ChatView_Previews: PreviewProvider {
//     static var previews: some View {
//         let state = UIState()
//         return Group {
//             if let conversation = state.conversations.first {
//                 ChatView(conversation: conversation)
//                     .environmentObject(state)
//             }
//         }
//     }
// }
