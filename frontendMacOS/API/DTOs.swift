import Foundation

// MARK: - Conversation DTOs

struct ConversationMetaDTO: Decodable {
    let id: UUID
    let title: String
    let modelId: String
    let isPinned: Bool
    let createdAt: Date
    let updatedAt: Date
    let lastMessage: MessageDTO?
}

struct ConversationDTO: Decodable {
    let id: UUID
    let title: String
    let modelId: String
    let isPinned: Bool
    let createdAt: Date
    let updatedAt: Date
    let messages: [MessageDTO]
}

struct ConversationListResponse: Decodable {
    let items: [ConversationMetaDTO]
    let nextCursor: String?
}

struct CreateConversationRequest: Encodable {
    let modelId: String
    let firstMessage: String?
}

struct CreateConversationResponse: Decodable {
    let conversation: ConversationDTO
}

struct UpdateConversationRequest: Encodable {
    let title: String?
    let modelId: String?
    let isPinned: Bool?
}

// MARK: - Message DTOs

struct MessageDTO: Decodable, Encodable {
    let id: UUID
    let role: String
    let text: String
    let createdAt: Date
    let isPinned: Bool?
    let isEdited: Bool?
}

struct MessageListResponse: Decodable {
    let items: [MessageDTO]
    let nextCursor: String?
}

struct SendMessageRequest: Encodable {
    let role: String
    let text: String
}

// MARK: - Model DTOs

struct ChatModelDTO: Decodable {
    let id: String
    let name: String
    let description: String?
}

// MARK: - SSE Event Data

struct SSEMessageData {
    let conversationId: UUID?
    let messageId: UUID?
    let deltaText: String?
    let fullText: String?
    let done: Bool?
    
    init(from dict: [String: Any]) {
        if let convIdStr = dict["conversationId"] as? String {
            self.conversationId = UUID(uuidString: convIdStr)
        } else {
            self.conversationId = nil
        }
        
        if let msgIdStr = dict["messageId"] as? String {
            self.messageId = UUID(uuidString: msgIdStr)
        } else {
            self.messageId = nil
        }
        
        self.deltaText = dict["deltaText"] as? String
        self.fullText = dict["fullText"] as? String
        self.done = dict["done"] as? Bool
    }
}

// MARK: - Domain Model Mapping Extensions

extension ConversationMetaDTO {
    func toDomain() -> Conversation {
        Conversation(
            id: id,
            title: title,
            modelId: modelId,
            isPinned: isPinned,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: lastMessage.map { [$0.toDomain()] } ?? []
        )
    }
}

extension ConversationDTO {
    func toDomain() -> Conversation {
        Conversation(
            id: id,
            title: title,
            modelId: modelId,
            isPinned: isPinned,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: messages.map { $0.toDomain() }
        )
    }
}

extension MessageDTO {
    func toDomain() -> Message {
        let role: MessageRole
        switch self.role.lowercased() {
        case "user":
            role = .user
        case "assistant":
            role = .assistant
        case "system":
            role = .system
        default:
            role = .user
        }
        
        return Message(
            id: id,
            role: role,
            text: text,
            createdAt: createdAt,
            isPinned: isPinned ?? false,
            isEdited: isEdited ?? false
        )
    }
}

extension ChatModelDTO {
    func toDomain() -> ChatModel {
        ChatModel(
            id: id,
            displayName: name,
            description: description ?? ""
        )
    }
}

// MARK: - Domain to DTO Mapping

extension Message {
    func toDTO() -> MessageDTO {
        MessageDTO(
            id: id,
            role: role.rawValue,
            text: text,
            createdAt: createdAt,
            isPinned: isPinned,
            isEdited: isEdited
        )
    }
}
