import SwiftUI

struct AppColors {
    // Background colors (using light theme values for now)
    static let background = Color(hex: 0xF7F7F8)
    static let chatBackground = Color(hex: 0xFFFFFF)
    static let sidebarBackground = Color(hex: 0xECECF1)
    static let codeBackground = Color(hex: 0xF3F4F6)

    // UI element colors
    static let sidebarBorder = Color(hex: 0xD7D9E0)
    static let sidebarIcon = Color(hex: 0x6B6C74)
    static let divider = Color(hex: 0xE4E6EB)
    static let accent = Color(hex: 0x10A37F)

    // Text colors
    static let subtleText = Color(hex: 0x71727B)
    static let timestamp = Color(hex: 0x999AA3)

    // Control colors
    static let controlBackground = Color(hex: 0xFFFFFF)
    static let controlBorder = Color(hex: 0xD8DAE5)
    static let controlMuted = Color(hex: 0xF3F4FA)

    // Message bubble colors
    static let userBubble = Color(hex: 0xDCE8FF)
    static let assistantBubble = Color(hex: 0xF5F7FA)

    // Brand colors
    static let professionalViolet = Color(hex: 0x6D5BD0)
    static let professionalVioletSoft = Color(hex: 0xF1EEFF)

    // Feedback colors
    static let warning = Color(hex: 0xF4A261)
    static let error = Color(hex: 0xD14343)
}

private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
