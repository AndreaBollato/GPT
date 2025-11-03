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

    private var requestPhase: ConversationRequestPhase {
        uiState.phase(for: conversation.id)
    }

    private var topBarStatus: TopBarView.Status {
        switch requestPhase {
        case .idle:
            return TopBarView.Status(text: "Pronto", color: AppColors.subtleText)
        case .sending:
            return TopBarView.Status(text: "Invio richiesta...", color: AppColors.warning)
        case .streaming:
            return TopBarView.Status(text: "Risposta in corso", color: AppColors.accent)
        case .error:
            return TopBarView.Status(text: "Errore", color: AppColors.error)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(
                title: conversation.title,
                status: topBarStatus,
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
                isStreaming: requestPhase.isInFlight,
                onStopStreaming: {
                    uiState.stopStreaming(for: conversation.id)
                }
            )
            Divider()
            messages
            Divider()
            ComposerView(
                text: draftBinding,
                placeholder: "Invia un messaggio",
                phase: requestPhase,
                onSubmit: submitMessage,
                onStop: {
                    uiState.stopStreaming(for: conversation.id)
                },
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
            .onChange(of: requestPhase) { _ in
                if requestPhase.isInFlight {
                    scrollToBottom(proxy: proxy)
                }
            }
            .overlay(alignment: .top) {
                requestOverlay
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

    @ViewBuilder
    private var requestOverlay: some View {
        switch requestPhase {
        case .sending:
            overlayContent(text: "Richiesta in corso...", tint: AppColors.warning)
        case .streaming:
            overlayContent(text: "Streaming della risposta...", tint: AppColors.accent)
        case .error, .idle:
            EmptyView()
        }
    }

    private func overlayContent(text: String, tint: Color) -> some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .tint(tint)
            Text(text)
                .font(AppTypography.badge)
                .foregroundColor(AppColors.subtleText)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, AppConstants.Spacing.sm)
        .background(
            Capsule(style: .continuous)
                .fill(AppColors.controlBackground.opacity(0.95))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.15), radius: 12, x: 0, y: 6)
        .padding(.top, AppConstants.Spacing.lg)
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
