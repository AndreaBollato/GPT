import Foundation

struct ChatModel: Identifiable, Hashable, Codable {
    var id: String
    var displayName: String
    var description: String

    init(id: String, displayName: String, description: String) {
        self.id = id
        self.displayName = displayName
        self.description = description
    }
}

struct Conversation: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var modelId: String
    var isPinned: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var messages: [Message] = []

    init(id: UUID = UUID(),
         title: String,
         modelId: String,
         isPinned: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         messages: [Message] = []) {
        self.id = id
        self.title = title
        self.modelId = modelId
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }

    var lastMessage: Message? {
        messages.last
    }

    var lastMessageSnippet: String {
        guard let message = lastMessage else { return "" }
        return message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }

    var lastActivityDate: Date {
        lastMessage?.createdAt ?? updatedAt
    }

    func updatingMessages(_ transform: (inout [Message]) -> Void) -> Conversation {
        var copy = self
        transform(&copy.messages)
        copy.updatedAt = Date()
        return copy
    }

    func updatingTitle(_ title: String) -> Conversation {
        var copy = self
        copy.title = title
        copy.updatedAt = Date()
        return copy
    }

    func updatingModel(_ modelId: String) -> Conversation {
        var copy = self
        copy.modelId = modelId
        copy.updatedAt = Date()
        return copy
    }

    func withPinned(_ isPinned: Bool) -> Conversation {
        var copy = self
        copy.isPinned = isPinned
        copy.updatedAt = Date()
        return copy
    }
}
