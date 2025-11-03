import SwiftUI

enum AppConstants {
    enum API {
        static let baseURL = "http://127.0.0.1:8000"
        static let useRemoteBackend = true // Set to false to fall back to dati locali mock
    }
    
    enum Layout {
        static let sidebarMinWidth: CGFloat = 260
        static let sidebarIdealWidth: CGFloat = 300
        static let sidebarMaxWidth: CGFloat = 360
        static let detailMaxWidth: CGFloat = 860
        static let messageMaxWidth: CGFloat = 720
        static let composerMinHeight: CGFloat = 42
        static let composerMaxHeight: CGFloat = 220
        static let cardCornerRadius: CGFloat = 14
        static let bubbleCornerRadius: CGFloat = 16
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    enum Animation {
        static let easeInOut: SwiftUI.Animation = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smoothSpring: SwiftUI.Animation = SwiftUI.Animation.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.2)
    }

    enum KeyboardShortcuts {
        static let newConversation = KeyboardShortcut(KeyEquivalent("n"), modifiers: [.command])
        static let searchConversations = KeyboardShortcut(KeyEquivalent("f"), modifiers: [.command])
        static let sendMessage = KeyboardShortcut(KeyEquivalent.return, modifiers: [.command])
        static let toggleSidebar = KeyboardShortcut(KeyEquivalent("b"), modifiers: [.command])
        static let stopStreaming = KeyboardShortcut(KeyEquivalent.escape, modifiers: [])
    }
}
