import SwiftUI

struct AvatarView: View {
    let role: MessageRole
    var size: CGFloat = 30

    private var backgroundColor: Color {
        role.isUser ? AppColors.userBubble.opacity(0.8) : AppColors.assistantBubble.opacity(0.9)
    }

    private var symbolName: String {
        switch role {
        case .user:
            return "person.fill"
        case .assistant:
            return "sparkles"
        case .system:
            return "gearshape"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
            Image(systemName: symbolName)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(role.isUser ? .primary : AppColors.accent)
        }
        .frame(width: size, height: size)
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            AvatarView(role: .assistant)
            AvatarView(role: .user)
            AvatarView(role: .system)
        }
        .padding()
        .background(AppColors.background)
    }
}
