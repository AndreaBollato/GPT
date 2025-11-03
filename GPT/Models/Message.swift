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
    enum Status: Hashable, Codable {
        case pending
        case streaming
        case complete
        case error(String)
    }

    var id: UUID = UUID()
    var role: MessageRole
    var text: String
    var status: Status = .complete
    var createdAt: Date = Date()
    var isPinned: Bool = false
    var isEdited: Bool = false

    init(id: UUID = UUID(),
         role: MessageRole,
         text: String,
         status: Status = .complete,
         createdAt: Date = Date(),
         isPinned: Bool = false,
         isEdited: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.status = status
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.isEdited = isEdited
    }
}
