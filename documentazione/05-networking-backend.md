# Networking e Comunicazione con il Backend

## Introduzione

Questa sezione descrive in dettaglio il layer di networking dell'applicazione, che gestisce tutta la comunicazione con il backend Python. Include sia richieste HTTP tradizionali che streaming in tempo reale tramite Server-Sent Events (SSE).

## Architettura di Networking

### Stack Tecnologico

- **Foundation URLSession**: Client HTTP nativo di Apple
- **Async/Await**: Per gestione asincrona moderna
- **AsyncThrowingStream**: Per streaming SSE
- **JSONEncoder/Decoder**: Serializzazione automatica

### Componenti Principali

```
Networking Layer
├── HTTPClient.swift      # Client HTTP generico
├── SSEClient.swift       # Client Server-Sent Events
│
API Layer  
├── Endpoints.swift       # Definizioni endpoint
├── DTOs.swift           # Data Transfer Objects
└── Decoders.swift       # Custom JSON decoders
```

## HTTPClient - Client HTTP Generico

### Responsabilità

HTTPClient è un wrapper type-safe attorno a URLSession che:

1. Costruisce URL da Endpoint definitions
2. Serializza body delle richieste in JSON
3. Esegue richieste HTTP
4. Gestisce errori HTTP
5. Deserializza risposte JSON in tipi Swift

### Struttura Base

```swift
struct HTTPClient {
    let baseURL: URL
    let session: URLSession
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
}
```

### Metodo Principale: request<T>

```swift
func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
    // 1. Costruisce URL completo
    var urlComponents = URLComponents(
        url: baseURL.appendingPathComponent(endpoint.path),
        resolvingAgainstBaseURL: true
    )
    urlComponents?.queryItems = endpoint.query
    
    guard let url = urlComponents?.url else {
        throw HTTPError.invalidURL
    }
    
    // 2. Crea URLRequest
    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    
    // 3. Aggiunge headers
    for (key, value) in endpoint.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }
    
    // 4. Serializza body se presente
    if let body = endpoint.body {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw HTTPError.encodingError(error)
        }
    }
    
    // 5. Esegue la richiesta
    let (data, response) = try await session.data(for: request)
    
    // 6. Valida status code
    guard let httpResponse = response as? HTTPURLResponse else {
        throw HTTPError.invalidResponse
    }
    
    guard (200...299).contains(httpResponse.statusCode) else {
        throw HTTPError.httpError(
            statusCode: httpResponse.statusCode,
            data: data
        )
    }
    
    // 7. Deserializza risposta
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    } catch {
        throw HTTPError.decodingError(error)
    }
}
```

### Variante per URLRequest

Per SSE, che necessita dell'URLRequest completo:

```swift
func urlRequest(for endpoint: Endpoint) throws -> URLRequest {
    var urlComponents = URLComponents(
        url: baseURL.appendingPathComponent(endpoint.path),
        resolvingAgainstBaseURL: true
    )
    urlComponents?.queryItems = endpoint.query
    
    guard let url = urlComponents?.url else {
        throw HTTPError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    
    for (key, value) in endpoint.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }
    
    if let body = endpoint.body {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
    }
    
    return request
}
```

### Gestione Errori

```swift
enum HTTPError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case networkError(Error)
    case encodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        }
    }
}
```

### Esempio d'Uso

```swift
// Setup
let baseURL = URL(string: "http://127.0.0.1:8000")!
let client = HTTPClient(baseURL: baseURL)

// Richiesta GET
let endpoint = Endpoints.listConversations(limit: 10, cursor: nil)
let response: ConversationListResponse = try await client.request(endpoint)

// Richiesta POST
let createEndpoint = Endpoints.createConversation(modelId: "gpt-4")
let conversation: ConversationDTO = try await client.request(createEndpoint)
```

## SSEClient - Client Server-Sent Events

### Responsabilità

SSEClient gestisce lo streaming in tempo reale delle risposte AI:

1. Apre connessione SSE al backend
2. Legge byte stream
3. Parsa eventi SSE
4. Deserializza JSON degli eventi
5. Gestisce cancellazione e chiusura stream

### Struttura

```swift
final class SSEClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func stream(urlRequest: URLRequest) -> AsyncThrowingStream<SSEEvent, Error>
}
```

### Formato SSE

Il backend invia eventi nel formato:

```
data: {"conversationId":"uuid","messageId":"uuid","deltaText":"Hello","done":false}

data: {"conversationId":"uuid","messageId":"uuid","deltaText":" World","done":false}

data: {"conversationId":"uuid","messageId":"uuid","deltaText":"","done":true}
```

### Implementazione Stream

```swift
func stream(urlRequest: URLRequest) -> AsyncThrowingStream<SSEEvent, Error> {
    AsyncThrowingStream { continuation in
        let task = Task {
            do {
                // Prepara richiesta
                var request = urlRequest
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 300  // 5 minuti per stream lunghi
                
                // Apre stream byte
                let (bytes, response) = try await session.bytes(for: request)
                
                // Valida risposta
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.finish(throwing: SSEError.invalidResponse)
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    continuation.finish(throwing: SSEError.invalidResponse)
                    return
                }
                
                // Legge e parsa byte
                var buffer = ""
                
                for try await byte in bytes {
                    // Controlla cancellazione
                    guard !Task.isCancelled else {
                        continuation.finish()
                        return
                    }
                    
                    // Accumula caratteri
                    let char = Character(UnicodeScalar(byte))
                    
                    if char == "\n" {
                        // Fine linea - processa se è data
                        if buffer.hasPrefix("data: ") {
                            let jsonString = String(buffer.dropFirst(6))
                            
                            if let data = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                let event = SSEEvent(data: json)
                                continuation.yield(event)
                            }
                        }
                        buffer = ""
                    } else {
                        buffer.append(char)
                    }
                }
                
                // Stream completato
                continuation.finish()
                
            } catch {
                // Errore durante stream
                continuation.finish(throwing: SSEError.networkError(error))
            }
        }
        
        // Gestione cancellazione
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
    }
}
```

### SSEEvent e Helpers

```swift
struct SSEEvent {
    let data: [String: Any]
    
    init(data: [String: Any]) {
        self.data = data
    }
}

struct SSEMessageData {
    let conversationId: UUID?
    let messageId: UUID?
    let deltaText: String?
    let done: Bool?
    
    init(from eventData: [String: Any]) {
        if let idStr = eventData["conversationId"] as? String {
            conversationId = UUID(uuidString: idStr)
        } else {
            conversationId = nil
        }
        
        if let idStr = eventData["messageId"] as? String {
            messageId = UUID(uuidString: idStr)
        } else {
            messageId = nil
        }
        
        deltaText = eventData["deltaText"] as? String
        done = eventData["done"] as? Bool
    }
}
```

### Gestione Errori SSE

```swift
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
```

### Esempio d'Uso SSE

```swift
// Prepara richiesta
let endpoint = Endpoints.sendMessage(conversationId: uuid, text: "Hello")
let urlRequest = try client.urlRequest(for: endpoint)

// Avvia stream
let stream = sseClient.stream(urlRequest: urlRequest)

// Consuma stream
for try await event in stream {
    let eventData = SSEMessageData(from: event.data)
    
    if let delta = eventData.deltaText {
        // Aggiungi delta al messaggio
        messageText += delta
    }
    
    if eventData.done == true {
        // Stream completato
        break
    }
}
```

## Endpoints - Definizioni Type-Safe

### Struttura Endpoint

```swift
struct Endpoint {
    var path: String
    var method: HTTPMethod
    var query: [URLQueryItem]
    var body: Encodable?
    var headers: [String: String]
}

enum HTTPMethod: String {
    case GET, POST, PATCH, DELETE
}
```

### Endpoints Statici

```swift
enum Endpoints {
    // Modelli
    static func listModels() -> Endpoint {
        Endpoint(path: "/models", method: .GET)
    }
    
    // Conversazioni
    static func listConversations(limit: Int = 10, cursor: String? = nil) -> Endpoint {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        if let cursor = cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(path: "/conversations", method: .GET, query: query)
    }
    
    static func getConversation(id: UUID) -> Endpoint {
        Endpoint(path: "/conversations/\(id.uuidString)", method: .GET)
    }
    
    static func createConversation(modelId: String, initialMessage: String? = nil) -> Endpoint {
        let request = CreateConversationRequest(
            modelId: modelId,
            initialMessage: initialMessage
        )
        return Endpoint(
            path: "/conversations",
            method: .POST,
            body: request
        )
    }
    
    static func updateConversation(
        id: UUID,
        title: String? = nil,
        modelId: String? = nil,
        isPinned: Bool? = nil
    ) -> Endpoint {
        let request = UpdateConversationRequest(
            title: title,
            modelId: modelId,
            isPinned: isPinned
        )
        return Endpoint(
            path: "/conversations/\(id.uuidString)",
            method: .PATCH,
            body: request
        )
    }
    
    static func deleteConversation(id: UUID) -> Endpoint {
        Endpoint(path: "/conversations/\(id.uuidString)", method: .DELETE)
    }
    
    static func duplicateConversation(id: UUID) -> Endpoint {
        Endpoint(
            path: "/conversations/\(id.uuidString)/duplicate",
            method: .POST
        )
    }
    
    // Messaggi
    static func listMessages(
        conversationId: UUID,
        limit: Int = 30,
        cursor: String? = nil
    ) -> Endpoint {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        if let cursor = cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(
            path: "/conversations/\(conversationId.uuidString)/messages",
            method: .GET,
            query: query
        )
    }
    
    static func sendMessage(conversationId: UUID, text: String) -> Endpoint {
        let request = SendMessageRequest(text: text)
        return Endpoint(
            path: "/conversations/\(conversationId.uuidString)/messages",
            method: .POST,
            body: request
        )
    }
}
```

## DTOs - Data Transfer Objects

### Request DTOs

```swift
struct CreateConversationRequest: Codable {
    let modelId: String
    let initialMessage: String?
}

struct UpdateConversationRequest: Codable {
    let title: String?
    let modelId: String?
    let isPinned: Bool?
}

struct SendMessageRequest: Codable {
    let text: String
}
```

### Response DTOs

```swift
struct ChatModelDTO: Codable {
    let id: String
    let displayName: String
    let description: String
    
    func toDomain() -> ChatModel {
        ChatModel(
            id: id,
            displayName: displayName,
            description: description
        )
    }
}

struct ConversationDTO: Codable {
    let id: String
    let title: String
    let modelId: String
    let isPinned: Bool
    let createdAt: String  // ISO8601
    let updatedAt: String  // ISO8601
    
    func toDomain() -> Conversation {
        let formatter = ISO8601DateFormatter()
        return Conversation(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            modelId: modelId,
            isPinned: isPinned,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            updatedAt: formatter.date(from: updatedAt) ?? Date()
        )
    }
}

struct MessageDTO: Codable {
    let id: String
    let role: String
    let text: String
    let createdAt: String
    
    func toDomain() -> Message {
        let formatter = ISO8601DateFormatter()
        let messageRole = MessageRole(rawValue: role) ?? .assistant
        
        return Message(
            id: UUID(uuidString: id) ?? UUID(),
            role: messageRole,
            text: text,
            status: .complete,
            createdAt: formatter.date(from: createdAt) ?? Date()
        )
    }
}

struct ConversationListResponse: Codable {
    let items: [ConversationDTO]
    let nextCursor: String?
}

struct MessageListResponse: Codable {
    let items: [MessageDTO]
    let nextCursor: String?
}
```

## Contratto API con il Backend

### Base URL

```
http://127.0.0.1:8000
```

Configurabile in `AppConstants.API.baseURL`.

### Endpoints Disponibili

#### 1. Elenco Modelli

```
GET /models
Response: [ChatModelDTO]
```

Esempio:
```json
[
  {
    "id": "gpt-4",
    "displayName": "GPT-4",
    "description": "Most capable model"
  }
]
```

#### 2. Elenco Conversazioni (Paginato)

```
GET /conversations?limit=10&cursor=abc123
Response: ConversationListResponse
```

Esempio:
```json
{
  "items": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "title": "Chat about Swift",
      "modelId": "gpt-4",
      "isPinned": false,
      "createdAt": "2025-11-03T14:00:00Z",
      "updatedAt": "2025-11-03T15:00:00Z"
    }
  ],
  "nextCursor": "xyz789"
}
```

#### 3. Dettaglio Conversazione

```
GET /conversations/{id}
Response: ConversationDTO
```

#### 4. Creazione Conversazione

```
POST /conversations
Body: CreateConversationRequest
Response: ConversationDTO
```

Esempio body:
```json
{
  "modelId": "gpt-4",
  "initialMessage": "Hello!"
}
```

#### 5. Aggiornamento Conversazione

```
PATCH /conversations/{id}
Body: UpdateConversationRequest
Response: ConversationDTO
```

Esempio body:
```json
{
  "title": "New Title",
  "isPinned": true
}
```

#### 6. Eliminazione Conversazione

```
DELETE /conversations/{id}
Response: 204 No Content
```

#### 7. Duplicazione Conversazione

```
POST /conversations/{id}/duplicate
Response: ConversationDTO
```

#### 8. Elenco Messaggi (Paginato)

```
GET /conversations/{id}/messages?limit=30&cursor=abc123
Response: MessageListResponse
```

#### 9. Invio Messaggio (SSE Streaming)

```
POST /conversations/{id}/messages
Body: SendMessageRequest
Response: text/event-stream
```

Body:
```json
{
  "text": "Tell me about Swift"
}
```

Response stream:
```
data: {"conversationId":"uuid","messageId":"uuid","deltaText":"Swift","done":false}

data: {"conversationId":"uuid","messageId":"uuid","deltaText":" is","done":false}

data: {"conversationId":"uuid","messageId":"uuid","deltaText":"...","done":true}
```

## Gestione della Concorrenza

### Async/Await

Tutte le operazioni network sono asincrone:

```swift
Task {
    do {
        let conversations = try await repository.listConversations(limit: 10, cursor: nil)
        // Aggiorna UI
    } catch {
        // Gestisci errore
    }
}
```

### Actor per Thread Safety

StreamingCenter usa Actor per gestione thread-safe:

```swift
actor StreamingCenter {
    private var activeStreams: [UUID: Task<Void, Never>] = [:]
    
    func register(conversationId: UUID, task: Task<Void, Never>) {
        activeStreams[conversationId] = task
    }
    
    func cancel(conversationId: UUID) {
        activeStreams[conversationId]?.cancel()
        activeStreams.removeValue(forKey: conversationId)
    }
}
```

### Cancellazione Task

Gli stream SSE supportano cancellazione:

```swift
let task = Task {
    for try await event in stream {
        // Processa evento
        
        if Task.isCancelled {
            break
        }
    }
}

// Cancella quando necessario
task.cancel()
```

## Gestione Errori di Rete

### Try-Catch Pattern

```swift
do {
    let result = try await client.request(endpoint)
    // Successo
} catch let error as HTTPError {
    switch error {
    case .httpError(let statusCode, _):
        print("HTTP \(statusCode)")
    case .networkError(let networkError):
        print("Network: \(networkError)")
    default:
        print("Other: \(error)")
    }
} catch {
    print("Unknown: \(error)")
}
```

### Propagazione a UIState

```swift
func loadConversations() async {
    do {
        let (items, cursor) = try await repo.listConversations(limit: 10, cursor: nil)
        await MainActor.run {
            self.conversations = items
            self.conversationCursor = cursor
        }
    } catch {
        await MainActor.run {
            self.errorMessage = "Failed to load conversations: \(error.localizedDescription)"
        }
    }
}
```

## Best Practices

1. **Timeout Appropriati**: Imposta timeout diversi per richieste normali (30s) e stream (300s)
2. **Retry Logic**: Implementa retry con exponential backoff per errori transitori
3. **Request Deduplication**: Evita richieste duplicate per la stessa risorsa
4. **Caching**: Considera caching locale per dati frequentemente richiesti
5. **Error Handling**: Gestisci sempre tutti i tipi di errore possibili
6. **Cancellation**: Implementa sempre logica di cancellazione per task lunghi
7. **Type Safety**: Usa types forti per request/response, evita `Any`

## Conclusione

Il layer di networking dell'applicazione GPT fornisce un'astrazione pulita e type-safe sulla comunicazione HTTP/SSE. L'uso di async/await e AsyncThrowingStream rende il codice asincrono leggibile e manutenibile, mentre la separazione in Endpoints, DTOs e Clients facilita testing ed estensibilità.
