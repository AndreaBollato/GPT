import SwiftUI
import AppKit

struct AppColors {
    static let background = Color.dynamic(lightHex: 0xF7F7F8, darkHex: 0x1E1F24)
    static let chatBackground = Color.dynamic(lightHex: 0xFFFFFF, darkHex: 0x2A2C32)
    static let sidebarBackground = Color.dynamic(lightHex: 0xECECF1, darkHex: 0x1A1B20)
    static let sidebarBorder = Color.dynamic(lightHex: 0xD7D9E0, darkHex: 0x2E3036)
    static let sidebarIcon = Color.dynamic(lightHex: 0x6B6C74, darkHex: 0xA8A9B4)
    static let userBubble = Color.dynamic(lightHex: 0xDCE8FF, darkHex: 0x18314F)
    static let assistantBubble = Color.dynamic(lightHex: 0xF5F7FA, darkHex: 0x2F3036)
    static let codeBackground = Color.dynamic(lightHex: 0xF3F4F6, darkHex: 0x1F2024)
    static let divider = Color.dynamic(lightHex: 0xE4E6EB, darkHex: 0x2B2C33)
    static let accent = Color.dynamic(lightHex: 0x10A37F, darkHex: 0x10A37F)
    static let subtleText = Color.dynamic(lightHex: 0x71727B, darkHex: 0xB1B2C0)
    static let timestamp = Color.dynamic(lightHex: 0x999AA3, darkHex: 0x8A8B96)
}

private extension Color {
    static func dynamic(lightHex: UInt32, darkHex: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .vibrantDark, .aqua, .vibrantLight])
            let isDark = bestMatch == .darkAqua || bestMatch == .vibrantDark
            let hex = isDark ? darkHex : lightHex
            return NSColor(rgb: hex)
        }))
    }
}

private extension NSColor {
    convenience init(rgb: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}
