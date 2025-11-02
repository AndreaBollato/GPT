import Foundation

/// Actor to manage concurrent stream tasks per conversation
actor StreamingCenter {
    private var streams: [UUID: Task<Void, Never>] = [:]
    
    /// Start a new streaming task for a conversation, cancelling any existing one
    func start(id: UUID, task: Task<Void, Never>) {
        streams[id]?.cancel()
        streams[id] = task
    }
    
    /// Cancel the streaming task for a specific conversation
    func cancel(id: UUID) {
        streams[id]?.cancel()
        streams[id] = nil
    }
    
    /// Cancel all active streaming tasks
    func cancelAll() {
        streams.values.forEach { $0.cancel() }
        streams.removeAll()
    }
    
    /// Check if a conversation is currently streaming
    func isStreaming(id: UUID) -> Bool {
        streams[id] != nil
    }
}
