import Foundation

enum MessageRole: String, Codable, CaseIterable, Hashable {
    case user
    case assistant
    case system

    var isUser: Bool { self == .user }
    var isAssistant: Bool { self == .assistant }

    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "ChatGPT"
        case .system: return "System"
        }
    }
}

struct Message: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var role: MessageRole
    var text: String
    var createdAt: Date = Date()
    var isLoading: Bool = false
    var isPinned: Bool = false
    var isEdited: Bool = false

    init(id: UUID = UUID(),
         role: MessageRole,
         text: String,
         createdAt: Date = Date(),
         isLoading: Bool = false,
         isPinned: Bool = false,
         isEdited: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.isLoading = isLoading
        self.isPinned = isPinned
        self.isEdited = isEdited
    }
}
