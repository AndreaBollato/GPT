import SwiftUI

struct ConversationRowView: View {
    @EnvironmentObject private var uiState: UIState

    let conversation: Conversation
    let isSelected: Bool

    @State private var isHovering: Bool = false
    @State private var isRenaming: Bool = false
    @State private var renameText: String = ""
    @FocusState private var focusRename: Bool

    private var modelDisplayName: String {
        uiState.availableModels.first(where: { $0.id == conversation.modelId })?.displayName ?? conversation.modelId
    }

    private var relativeDate: String {
        Self.relativeFormatter.localizedString(for: conversation.lastActivityDate, relativeTo: Date())
    }

    private var rowBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(AppColors.chatBackground.opacity(0.6))
        } else if isHovering {
            return AnyShapeStyle(AppColors.sidebarBackground.opacity(0.6))
        } else {
            return AnyShapeStyle(Color.clear)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                if isRenaming {
                    TextField("Titolo conversazione", text: $renameText, onCommit: commitRename)
                        .textFieldStyle(.plain)
                        .font(.headline)
                        .focused($focusRename)
                        .onAppear { focusRename = true }
                } else {
                    Text(conversation.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()
                Text(relativeDate)
                    .font(AppTypography.badge)
                    .foregroundColor(AppColors.timestamp)
            }

            if let snippet = snippetText, !snippet.isEmpty {
                Text(snippet)
                    .font(.subheadline)
                    .foregroundColor(AppColors.subtleText)
                    .lineLimit(1)
            }

            HStack(spacing: AppConstants.Spacing.xs) {
                Text(modelDisplayName)
                    .font(AppTypography.badge)
                    .padding(.horizontal, AppConstants.Spacing.xs)
                    .padding(.vertical, AppConstants.Spacing.xxs)
                    .background(AppColors.sidebarBorder.opacity(0.35))
                    .clipShape(Capsule())

                if conversation.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .padding(.vertical, AppConstants.Spacing.sm)
        .padding(.horizontal, AppConstants.Spacing.sm)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture(count: 2) {
            startRenaming()
        }
        .contextMenu {
            Button(conversation.isPinned ? "Annulla pin" : "Metti in evidenza") {
                uiState.setPinned(!conversation.isPinned, for: conversation.id)
            }

            Button("Rinomina") {
                startRenaming()
            }

            Button("Duplica") {
                uiState.duplicateConversation(id: conversation.id)
            }

            Divider()

            Button("Elimina", role: .destructive) {
                uiState.deleteConversation(id: conversation.id)
            }
        }
        .onChange(of: isRenaming) { _, newValue in
            if newValue {
                renameText = conversation.title
            }
        }
        .onChange(of: conversation.title) { _, newValue in
            if !isRenaming {
                renameText = newValue
            }
        }
    }

    private var snippetText: String? {
        guard let message = conversation.lastMessage else { return nil }
        let trimmed = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func startRenaming() {
        renameText = conversation.title
        withAnimation(AppConstants.Animation.easeInOut) {
            isRenaming = true
        }
    }

    private func commitRename() {
        let newTitle = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newTitle.isEmpty else {
            cancelRename()
            return
        }
        uiState.updateTitle(newTitle, for: conversation.id)
        cancelRename()
    }

    private func cancelRename() {
        withAnimation(AppConstants.Animation.easeInOut) {
            isRenaming = false
        }
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

struct ConversationRowView_Previews: PreviewProvider {
    static var previews: some View {
        let uiState = UIState()
        return VStack(spacing: 12) {
            if let conversation = uiState.conversations.first {
                ConversationRowView(conversation: conversation, isSelected: true)
                ConversationRowView(conversation: conversation, isSelected: false)
            }
        }
        .padding()
        .frame(width: 320)
        .background(AppColors.sidebarBackground)
        .environmentObject(uiState)
    }
}
