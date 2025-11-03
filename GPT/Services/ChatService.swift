import Foundation

@MainActor
final class ChatService {
    private let repo: ConversationsRepository
    private let sse: SSEClient
    private let streams = StreamingCenter()

    init(repo: ConversationsRepository, sse: SSEClient? = nil) {
        self.repo = repo
        self.sse = sse ?? SSEClient()
    }
    
    /// Stream a reply from the assistant for the given conversation
    /// - Parameters:
    ///   - conversationId: The conversation to stream for
    ///   - userText: The user's message text
    ///   - onDelta: Called for each text delta received
    ///   - onDone: Called when streaming completes
    ///   - onError: Called if an error occurs
    func streamReply(
        conversationId: UUID,
        userText: String,
        onDelta: @escaping (String) -> Void,
        onDone: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) async {
        do {
            let request = try await repo.sendMessage(conversationId: conversationId, text: userText)
            let stream = sse.stream(urlRequest: request)
            
            let task = Task { [onDelta, onDone, onError] in
                do {
                    for try await event in stream {
                        guard !Task.isCancelled else {
                            await MainActor.run { onDone() }
                            return
                        }
                        
                        let eventData = SSEMessageData(from: event.data)
                        
                        if let delta = eventData.deltaText {
                            await MainActor.run {
                                onDelta(delta)
                            }
                        }
                        
                        if eventData.done == true {
                            await MainActor.run { onDone() }
                            break
                        }
                    }
                } catch {
                    if !Task.isCancelled {
                        await MainActor.run {
                            onError(error)
                        }
                    }
                }
            }
            
            await streams.start(id: conversationId, task: task)
        } catch {
            onError(error)
        }
    }
    
    /// Stop streaming for a specific conversation
    func stop(conversationId: UUID) async {
        await streams.cancel(id: conversationId)
    }
    
    /// Stop all active streams
    func stopAll() async {
        await streams.cancelAll()
    }
    
    /// Check if a conversation is currently streaming
    func isStreaming(conversationId: UUID) async -> Bool {
        await streams.isStreaming(id: conversationId)
    }
}
