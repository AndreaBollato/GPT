import Foundation

struct Endpoints {
    // MARK: - Conversations
    
    static func listConversations(limit: Int = 10, cursor: String? = nil) -> Endpoint {
        var query: [URLQueryItem] = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let cursor = cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(path: "conversations", method: .GET, query: query)
    }
    
    static func createConversation(request: CreateConversationRequest) -> Endpoint {
        Endpoint(path: "conversations", method: .POST, body: request)
    }
    
    static func getConversation(id: UUID) -> Endpoint {
        Endpoint(path: "conversations/\(id.uuidString)", method: .GET)
    }
    
    static func updateConversation(id: UUID, request: UpdateConversationRequest) -> Endpoint {
        Endpoint(path: "conversations/\(id.uuidString)", method: .PATCH, body: request)
    }
    
    static func deleteConversation(id: UUID) -> Endpoint {
        Endpoint(path: "conversations/\(id.uuidString)", method: .DELETE)
    }
    
    static func duplicateConversation(id: UUID) -> Endpoint {
        Endpoint(path: "conversations/\(id.uuidString)/duplicate", method: .POST)
    }
    
    // MARK: - Messages
    
    static func listMessages(conversationId: UUID, limit: Int = 30, cursor: String? = nil) -> Endpoint {
        var query: [URLQueryItem] = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let cursor = cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(path: "conversations/\(conversationId.uuidString)/messages", method: .GET, query: query)
    }
    
    static func sendMessage(conversationId: UUID, request: SendMessageRequest) -> Endpoint {
        Endpoint(path: "conversations/\(conversationId.uuidString)/messages", method: .POST, body: request)
    }
    
    // MARK: - Models
    
    static func listModels() -> Endpoint {
        Endpoint(path: "models", method: .GET)
    }
}
