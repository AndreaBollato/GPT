import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.white)
                .font(.system(size: 18, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.white.opacity(0.85))
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, AppConstants.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColors.error.opacity(0.95), AppColors.error.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: AppColors.error.opacity(0.35), radius: 12, x: 0, y: 8)
    }
}

struct ErrorBanner_Previews: PreviewProvider {
    static var previews: some View {
        ErrorBanner(message: "Failed to load conversations", onDismiss: {})
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
