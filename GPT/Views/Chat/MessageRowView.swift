import SwiftUI

struct MessageRowView: View {
    let message: Message

    @State private var isHovering: Bool = false

    private var isUser: Bool { message.role.isUser }

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
                if message.isLoading {
                    skeleton
                } else if message.role.isAssistant || message.role == .system {
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
        if message.role.isAssistant || message.role == .system {
            return AnyShapeStyle(AppColors.assistantBubble)
        } else {
            return AnyShapeStyle(AppColors.userBubble)
        }
    }

    private var bubbleBorder: some View {
        Group {
            if message.role.isAssistant || message.role == .system {
                RoundedRectangle(cornerRadius: AppConstants.Layout.bubbleCornerRadius, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            }
        }
    }

    private var skeleton: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.divider.opacity(0.5))
                .frame(width: 220, height: 12)
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.divider.opacity(0.35))
                .frame(width: 280, height: 12)
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.divider.opacity(0.25))
                .frame(width: 180, height: 12)
        }
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
