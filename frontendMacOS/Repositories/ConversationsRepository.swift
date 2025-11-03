import Foundation

protocol ConversationsRepository {
    func fetchModels() async throws -> [ChatModel]
    func listConversations(limit: Int, cursor: String?) async throws -> (items: [Conversation], nextCursor: String?)
    func getConversation(id: UUID) async throws -> Conversation
    func getMessages(conversationId: UUID, limit: Int, cursor: String?) async throws -> (items: [Message], nextCursor: String?)
    func createConversation(initialMessage: Message?, modelId: String) async throws -> Conversation
    func updateConversation(id: UUID, title: String?, modelId: String?, isPinned: Bool?) async throws -> Conversation
    func deleteConversation(id: UUID) async throws
    func duplicateConversation(id: UUID) async throws -> Conversation
    func sendMessage(conversationId: UUID, text: String) async throws -> URLRequest
}

final class RemoteConversationsRepository: ConversationsRepository {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func fetchModels() async throws -> [ChatModel] {
        let endpoint = Endpoints.listModels()
        let dtos: [ChatModelDTO] = try await client.request(endpoint)
        return dtos.map { $0.toDomain() }
    }
    
    func listConversations(limit: Int = 10, cursor: String? = nil) async throws -> (items: [Conversation], nextCursor: String?) {
        let endpoint = Endpoints.listConversations(limit: limit, cursor: cursor)
        let response: ConversationListResponse = try await client.request(endpoint)
        let conversations = response.items.map { $0.toDomain() }
        return (items: conversations, nextCursor: response.nextCursor)
    }
    
    func getConversation(id: UUID) async throws -> Conversation {
        let endpoint = Endpoints.getConversation(id: id)
        let dto: ConversationDTO = try await client.request(endpoint)
        return dto.toDomain()
    }
    
    func getMessages(conversationId: UUID, limit: Int = 30, cursor: String? = nil) async throws -> (items: [Message], nextCursor: String?) {
        let endpoint = Endpoints.listMessages(conversationId: conversationId, limit: limit, cursor: cursor)
        let response: MessageListResponse = try await client.request(endpoint)
        let messages = response.items.map { $0.toDomain() }
        return (items: messages, nextCursor: response.nextCursor)
    }
    
    func createConversation(initialMessage: Message? = nil, modelId: String) async throws -> Conversation {
        let request = CreateConversationRequest(
            modelId: modelId,
            firstMessage: initialMessage?.text
        )
        let endpoint = Endpoints.createConversation(request: request)
        let response: CreateConversationResponse = try await client.request(endpoint)
        return response.conversation.toDomain()
    }
    
    func updateConversation(id: UUID, title: String? = nil, modelId: String? = nil, isPinned: Bool? = nil) async throws -> Conversation {
        let request = UpdateConversationRequest(
            title: title,
            modelId: modelId,
            isPinned: isPinned
        )
        let endpoint = Endpoints.updateConversation(id: id, request: request)
        let dto: ConversationDTO = try await client.request(endpoint)
        return dto.toDomain()
    }
    
    func deleteConversation(id: UUID) async throws {
        let endpoint = Endpoints.deleteConversation(id: id)
        try await client.requestVoid(endpoint)
    }
    
    func duplicateConversation(id: UUID) async throws -> Conversation {
        let endpoint = Endpoints.duplicateConversation(id: id)
        let dto: ConversationDTO = try await client.request(endpoint)
        return dto.toDomain()
    }
    
    func sendMessage(conversationId: UUID, text: String) async throws -> URLRequest {
        let request = SendMessageRequest(role: "user", text: text)
        let endpoint = Endpoints.sendMessage(conversationId: conversationId, request: request)
        return try client.makeRequest(endpoint)
    }
}
