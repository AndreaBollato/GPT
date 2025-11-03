import SwiftUI

struct MessageRowView: View {
    let message: Message

    @State private var isHovering: Bool = false

    private var isUser: Bool { message.role.isUser }
    private var isError: Bool {
        if case .error = message.status { return true }
        return false
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.md) {
            if isUser {
                Spacer(minLength: 60)
                bubble
                AvatarView(role: message.role, size: 28)
            } else {
                AvatarView(role: message.role, size: 28)
                bubble
                Spacer(minLength: 60)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, AppConstants.Spacing.xl)
        .padding(.vertical, AppConstants.Spacing.sm)
    }

    private var bubble: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: AppConstants.Spacing.xs) {
            Group {
                switch message.status {
                case .pending:
                    loadingContent
                case .streaming:
                    streamingContent
                case .complete:
                    completeContent
                case .error(let errorMessage):
                    errorContent(text: errorMessage)
                }
            }
            .padding(AppConstants.Spacing.lg)
            .background(bubbleBackground)
            .overlay(bubbleBorder)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.bubbleCornerRadius, style: .continuous))
            .onHover { hovering in
                isHovering = hovering
            }

            if isHovering {
                Text(timestamp)
                    .font(AppTypography.badge)
                    .foregroundColor(AppColors.timestamp)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: AppConstants.Layout.messageMaxWidth, alignment: isUser ? .trailing : .leading)
        .animation(AppConstants.Animation.easeInOut, value: isHovering)
    }

    private var bubbleBackground: some ShapeStyle {
        if isError {
            return AnyShapeStyle(AppColors.error.opacity(0.1))
        }
        if message.role.isAssistant || message.role == .system {
            return AnyShapeStyle(AppColors.assistantBubble)
        } else {
            return AnyShapeStyle(AppColors.userBubble)
        }
    }

    private var bubbleBorder: some View {
        Group {
            if isError {
                RoundedRectangle(cornerRadius: AppConstants.Layout.bubbleCornerRadius, style: .continuous)
                    .stroke(AppColors.error.opacity(0.6), lineWidth: 1)
            } else if message.role.isAssistant || message.role == .system {
                RoundedRectangle(cornerRadius: AppConstants.Layout.bubbleCornerRadius, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            }
        }
    }

    private var loadingContent: some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .tint(AppColors.accent)
            Text("Assistente sta scrivendo...")
                .font(AppTypography.badge)
                .foregroundColor(AppColors.subtleText)
        }
        .frame(maxWidth: AppConstants.Layout.messageMaxWidth, alignment: .leading)
    }

    private var streamingContent: some View {
        MarkdownMessageView(text: message.text)
            .frame(maxWidth: AppConstants.Layout.messageMaxWidth, alignment: .leading)
    }

    private var completeContent: some View {
        Group {
            if message.role.isAssistant || message.role == .system {
                MarkdownMessageView(text: message.text)
                    .frame(maxWidth: AppConstants.Layout.messageMaxWidth, alignment: .leading)
            } else {
                Text(message.text)
                    .font(AppTypography.messageBody)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: AppConstants.Layout.messageMaxWidth, alignment: .leading)
            }
        }
    }

    private func errorContent(text: String) -> some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.error)
                .padding(.top, 2)
            Text(text)
                .font(AppTypography.messageBody)
                .foregroundColor(AppColors.error)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: AppConstants.Layout.messageMaxWidth, alignment: .leading)
    }

    private var timestamp: String {
        Self.timeFormatter.string(from: message.createdAt)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct MessageRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            MessageRowView(message: Message(role: .assistant, text: "Certo! Ecco alcune idee per iniziare."))
            MessageRowView(message: Message(role: .user, text: "Puoi spiegarmi come impostare una NavigationSplitView?"))
        }
        .padding()
        .background(AppColors.background)
    }
}
