import SwiftUI

struct AppTypography {
    static let heroTitle = Font.system(size: 34, weight: .semibold, design: .default)
    static let heroSubtitle = Font.system(size: 18, weight: .regular, design: .default)
    static let sectionTitle = Font.system(size: 16, weight: .semibold, design: .default)
    static let messageBody = Font.system(size: 15, weight: .regular, design: .default)
    static let messageMono = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let timeStamp = Font.system(size: 12, weight: .regular, design: .default)
    static let badge = Font.system(size: 11, weight: .semibold, design: .rounded)

    static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }
}
