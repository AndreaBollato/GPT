import SwiftUI

struct AppButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
        case subtle
        case destructive
    }

    enum Size {
        case regular
        case small
    }

    var variant: Variant = .primary
    var size: Size = .regular
    var isIconOnly: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: size == .regular ? 38 : 30)
            .background(background(isPressed: configuration.isPressed))
            .overlay(border(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: shadowColor(isPressed: configuration.isPressed), radius: configuration.isPressed ? 2 : 6, x: 0, y: configuration.isPressed ? 1 : 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .regular: return 18
        case .small: return 14
        }
    }

    private var horizontalPadding: CGFloat {
        if isIconOnly { return size == .regular ? 12 : 10 }
        switch size {
        case .regular: return 18
        case .small: return 14
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .regular: return 10
        case .small: return 6
        }
    }

    private var font: Font {
        switch size {
        case .regular:
            return .system(size: 15, weight: .semibold)
        case .small:
            return .system(size: 13, weight: .semibold)
        }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return .white.opacity(isPressed ? 0.9 : 1.0)
        case .secondary:
            return Color.primary.opacity(isPressed ? 0.85 : 1.0)
        case .subtle:
            return AppColors.subtleText.opacity(isPressed ? 0.9 : 1.0)
        case .destructive:
            return .white.opacity(isPressed ? 0.9 : 1.0)
        }
    }

    private func background(isPressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(backgroundColor(isPressed: isPressed))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return AppColors.accent.opacity(isPressed ? 0.9 : 1.0)
        case .secondary:
            return AppColors.controlBackground.opacity(isPressed ? 0.95 : 1.0)
        case .subtle:
            return AppColors.controlMuted.opacity(isPressed ? 0.9 : 1.0)
        case .destructive:
            return Color.red.opacity(isPressed ? 0.85 : 0.95)
        }
    }

    private func border(isPressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(borderColor(isPressed: isPressed), lineWidth: borderWidth)
    }

    private func borderColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return Color.clear
        case .secondary:
            return AppColors.controlBorder.opacity(isPressed ? 0.9 : 1.0)
        case .subtle:
            return AppColors.controlBorder.opacity(isPressed ? 0.6 : 0.4)
        case .destructive:
            return Color.red.opacity(isPressed ? 0.7 : 0.55)
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .primary:
            return 0
        case .secondary, .subtle, .destructive:
            return 1
        }
    }

    private func shadowColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return AppColors.accent.opacity(isPressed ? 0.08 : 0.2)
        case .secondary, .subtle:
            return Color.black.opacity(isPressed ? 0.05 : 0.08)
        case .destructive:
            return Color.red.opacity(isPressed ? 0.1 : 0.18)
        }
    }
}

extension Button {
    func appButtonStyle(_ variant: AppButtonStyle.Variant = .primary, size: AppButtonStyle.Size = .regular, iconOnly: Bool = false) -> some View {
        self.buttonStyle(AppButtonStyle(variant: variant, size: size, isIconOnly: iconOnly))
    }
}
