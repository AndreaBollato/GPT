import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var uiState: UIState
    let conversation: Conversation

    @FocusState private var composerFocused: Bool

    private var draftBinding: Binding<String> {
        Binding(
            get: { uiState.draft(for: conversation.id) },
            set: { uiState.setDraft($0, for: conversation.id) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
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

    private var header: some View {
        HStack(alignment: .center, spacing: AppConstants.Spacing.lg) {
            ModelPickerView(selectedModelId: conversation.modelId) { modelId in
                uiState.updateModel(for: conversation.id, to: modelId)
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.xxs) {
                Text(conversation.title)
                    .font(.title3)
                    .lineLimit(1)
                statusLine
            }

            Spacer()

            if uiState.isStreamingResponse {
                Button(action: uiState.stopStreaming) {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(AppButtonStyle(variant: .destructive))
                .keyboardShortcut(AppConstants.KeyboardShortcuts.stopStreaming)
            }

            Button {
                uiState.beginNewChat()
            } label: {
                Label("Nuova chat", systemImage: "plus")
            }
            .buttonStyle(AppButtonStyle(variant: .secondary))
            .keyboardShortcut(AppConstants.KeyboardShortcuts.newConversation)

            Menu {
                Button("Pulisci chat") {
                    uiState.clearConversation(id: conversation.id)
                }
                Button("Duplica") {
                    uiState.duplicateConversation(id: conversation.id)
                }
                Divider()
                Button("Elimina", role: .destructive) {
                    uiState.deleteConversation(id: conversation.id)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(AppConstants.Spacing.sm)
                    .background(AppColors.controlBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppColors.controlBorder, lineWidth: 1)
                    )
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, AppConstants.Spacing.xl)
        .padding(.vertical, AppConstants.Spacing.lg)
        .background(AppColors.background)
    }

    private var statusLine: some View {
        HStack(spacing: AppConstants.Spacing.xs) {
            Circle()
                .fill(uiState.isStreamingResponse ? AppColors.accent : AppColors.subtleText)
                .frame(width: 8, height: 8)
            Text(uiState.isStreamingResponse ? "Risposta in corso" : "Pronto")
                .font(AppTypography.badge)
                .foregroundColor(AppColors.subtleText)
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

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let state = UIState()
        return Group {
            if let conversation = state.conversations.first {
                ChatView(conversation: conversation)
                    .environmentObject(state)
            }
        }
    }
}
