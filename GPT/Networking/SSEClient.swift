import Foundation

struct SSEEvent {
    let data: [String: Any]
    
    init(data: [String: Any]) {
        self.data = data
    }
}

enum SSEError: Error, LocalizedError {
    case invalidResponse
    case connectionClosed
    case parsingError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid SSE response"
        case .connectionClosed:
            return "SSE connection closed"
        case .parsingError(let message):
            return "SSE parsing error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

final class SSEClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Creates an async stream of SSE events from the given request
    func stream(urlRequest: URLRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = urlRequest
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.timeoutInterval = 300 // 5 minutes timeout for long-running streams
                    
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: SSEError.invalidResponse)
                        return
                    }
                    
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: HTTPError.httpError(statusCode: httpResponse.statusCode, data: nil))
                        return
                    }
                    
                    var buffer = ""
                    
                    for try await byte in bytes {
                        guard !Task.isCancelled else {
                            continuation.finish()
                            return
                        }
                        
                        let char = Character(UnicodeScalar(byte))
                        buffer.append(char)
                        
                        // SSE messages are delimited by double newline
                        if buffer.hasSuffix("\n\n") {
                            let message = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                            buffer = ""
                            
                            if let event = parseSSEMessage(message) {
                                continuation.yield(event)
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    if !Task.isCancelled {
                        continuation.finish(throwing: SSEError.networkError(error))
                    } else {
                        continuation.finish()
                    }
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    private func parseSSEMessage(_ message: String) -> SSEEvent? {
        var dataLines: [String] = []
        
        for line in message.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix(":") {
                continue
            }
            
            // Parse "data: {...}" lines
            if trimmed.hasPrefix("data:") {
                let dataContent = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                dataLines.append(dataContent)
            }
        }
        
        guard !dataLines.isEmpty else {
            return nil
        }
        
        // Join multiple data lines (some SSE servers split long messages)
        let combinedData = dataLines.joined(separator: "\n")
        
        // Parse JSON
        guard let jsonData = combinedData.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        
        return SSEEvent(data: json)
    }
}
