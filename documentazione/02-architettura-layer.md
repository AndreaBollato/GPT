# Architettura dei Layer dell'Applicazione

## Introduzione

Questa sezione descrive in dettaglio l'architettura a layer dell'applicazione GPT, spiegando come ogni livello interagisce con gli altri e le responsabilità specifiche di ciascuno.

## Panoramica dell'Architettura a Layer

L'applicazione è strutturata in 5 layer principali, ciascuno con responsabilità ben definite:

1. **Presentation Layer** (UI)
2. **State Management Layer** (ViewModels)
3. **Business Logic Layer** (Services)
4. **Data Access Layer** (Repositories + API)
5. **Network Layer** (HTTP + SSE Clients)

### Diagramma dell'Architettura

```
┌───────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                     │
│                                                           │
│  ┌─────────────┐  ┌──────────┐  ┌──────────┐           │
│  │ AppRootView │  │ ChatView │  │ Sidebar  │  + altre  │
│  └─────────────┘  └──────────┘  └──────────┘           │
│         │                │              │                │
│         └────────────────┴──────────────┘                │
└───────────────────────────┬───────────────────────────────┘
                            │
┌───────────────────────────▼───────────────────────────────┐
│                STATE MANAGEMENT LAYER                     │
│                                                           │
│              ┌─────────────────────┐                     │
│              │      UIState        │                     │
│              │  @ObservableObject  │                     │
│              └─────────────────────┘                     │
│                        │                                  │
└────────────────────────┼──────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
┌───────▼──────────────┐    ┌────────────▼──────────────┐
│ BUSINESS LOGIC LAYER │    │   DATA ACCESS LAYER       │
│                      │    │                           │
│  ┌───────────────┐  │    │  ┌────────────────────┐  │
│  │ ChatService   │  │    │  │ Conversations      │  │
│  └───────────────┘  │    │  │ Repository         │  │
│  ┌───────────────┐  │    │  └────────────────────┘  │
│  │ Streaming     │  │    │           │               │
│  │ Center        │  │    │  ┌────────▼────────┐     │
│  └───────────────┘  │    │  │   API Layer     │     │
└──────────┬───────────┘    │  │ (Endpoints,DTOs)│     │
           │                │  └─────────────────┘     │
           │                └───────────┬───────────────┘
           │                            │
           │    ┌───────────────────────┘
           │    │
┌──────────▼────▼────────────────────────────────────────┐
│                    NETWORK LAYER                       │
│                                                        │
│     ┌──────────────┐         ┌──────────────┐        │
│     │  HTTPClient  │         │  SSEClient   │        │
│     └──────────────┘         └──────────────┘        │
└────────────────────┬──────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
┌────────▼────────┐    ┌─────────▼─────────┐
│ Python Backend  │    │   Mock Store      │
│   (HTTP/SSE)    │    │  (Development)    │
└─────────────────┘    └───────────────────┘
```

## Layer 1: Presentation Layer

### Responsabilità

Il Presentation Layer è responsabile di:
- Renderizzare l'interfaccia utente
- Catturare l'input dell'utente
- Mostrare lo stato dell'applicazione
- Gestire animazioni e transizioni

### Componenti Principali

#### AppRootView.swift
La vista radice dell'applicazione che:
- Gestisce il NavigationSplitView (sidebar + detail)
- Mostra ErrorBanner per gli errori
- Inietta UIState come EnvironmentObject
- Gestisce la visibilità delle colonne

#### Struttura delle Viste

```
Views/
├── AppRootView.swift          # Vista radice
├── Chat/
│   ├── ChatView.swift         # Vista principale chat
│   ├── ComposerView.swift     # Input messaggi
│   ├── MessageRowView.swift   # Singolo messaggio
│   └── ModelPickerView.swift  # Selettore modelli
├── Sidebar/
│   ├── SidebarView.swift      # Barra laterale
│   └── ConversationRowView.swift  # Riga conversazione
├── Home/
│   └── HomeView.swift         # Vista iniziale
└── Shared/
    ├── AvatarView.swift       # Avatar utente/AI
    ├── CodeBlockView.swift    # Blocchi codice
    ├── ErrorBanner.swift      # Banner errori
    ├── MarkdownMessageView.swift  # Rendering markdown
    └── TopBarView.swift       # Barra superiore
```

#### Caratteristiche

- **Dichiarativo**: SwiftUI usa sintassi dichiarativa
- **Reattivo**: Si aggiorna automaticamente con @Published/@ObservableObject
- **Compositivo**: Viste piccole combinate in viste complesse
- **Animato**: Transizioni fluide con Animation API

### Interazione con gli Altri Layer

Le viste:
1. Osservano UIState tramite @EnvironmentObject o @ObservedObject
2. Chiamano metodi su UIState in risposta agli input utente
3. NON comunicano direttamente con Services o Repositories
4. Usano @Published properties per aggiornamenti automatici

## Layer 2: State Management Layer

### Responsabilità

Questo layer gestisce:
- Stato globale dell'applicazione
- Coordinamento tra UI e Business Logic
- Caching temporaneo dei dati
- Gestione degli stati di caricamento/errore

### UIState.swift

UIState è il cuore dello state management:

```swift
@MainActor
final class UIState: ObservableObject {
    // Stato pubblicato
    @Published private(set) var conversations: [Conversation] = []
    @Published var selectedConversationID: Conversation.ID?
    @Published var searchQuery: String = ""
    @Published var isStreamingResponse: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var availableModels: [ChatModel] = []
    
    // Dipendenze
    private let repo: ConversationsRepository?
    private let chatService: ChatService?
    private let store: ConversationsUIStore?
}
```

### Funzionalità Principali

#### 1. Gestione Conversazioni

```swift
func loadConversations() async
func createNewConversation(withMessage: String?, modelId: String) async
func deleteConversation(id: UUID) async
func duplicateConversation(id: UUID) async
func updateConversationTitle(id: UUID, newTitle: String) async
func togglePin(conversationId: UUID) async
```

#### 2. Gestione Messaggi

```swift
func sendMessage(_ text: String, in conversationId: UUID) async
func loadMoreMessages(for conversationId: UUID) async
func stopStreaming(for conversationId: UUID)
```

#### 3. Ricerca e Filtraggio

```swift
var pinnedConversations: [Conversation]
var recentConversations: [Conversation]
private func filteredConversations(includingPinned: Bool) -> [Conversation]
```

#### 4. Gestione Errori

```swift
private func handleError(_ error: Error, context: String)
```

### Pattern Observer

UIState usa il pattern Observer tramite Combine:
- `@Published` marca le properties che notificano i cambiamenti
- SwiftUI osserva automaticamente e ri-renderizza quando cambiano
- Garantisce thread-safety eseguendo tutto su MainActor

## Layer 3: Business Logic Layer

### Responsabilità

Il Business Logic Layer contiene:
- Logica di business dell'applicazione
- Orchestrazione di operazioni complesse
- Gestione dello streaming
- Coordinamento tra repository e UI

### ChatService.swift

Gestisce l'invio messaggi e lo streaming delle risposte:

```swift
@MainActor
final class ChatService {
    private let repo: ConversationsRepository
    private let sse: SSEClient
    private let streams = StreamingCenter()
    
    func streamReply(
        conversationId: UUID,
        userText: String,
        onDelta: @escaping (String) -> Void,
        onDone: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) async
    
    func cancelStream(for conversationId: UUID)
}
```

#### Flusso di Streaming

1. Riceve richiesta di streaming da UIState
2. Ottiene URLRequest dal repository
3. Passa la richiesta a SSEClient
4. Registra lo stream in StreamingCenter
5. Per ogni delta ricevuto, chiama onDelta callback
6. Alla fine, chiama onDone e pulisce

### StreamingCenter.swift

Actor thread-safe per gestire stream concorrenti:

```swift
actor StreamingCenter {
    private var activeStreams: [UUID: Task<Void, Never>] = [:]
    
    func register(conversationId: UUID, task: Task<Void, Never>)
    func cancel(conversationId: UUID)
    func cancelAll()
    func isActive(conversationId: UUID) -> Bool
}
```

#### Perché un Actor?

- **Thread Safety**: Garantisce accesso seriale al dizionario
- **No Locks**: Nessun bisogno di lock espliciti
- **Async-First**: Integrazione naturale con async/await

## Layer 4: Data Access Layer

### Responsabilità

Il Data Access Layer gestisce:
- Accesso ai dati (remoti o locali)
- Mapping tra DTOs e Domain Models
- Caching (se implementato)
- Astrazione della sorgente dati

### Struttura

```
Repositories/
└── ConversationsRepository.swift  # Protocollo + Implementazioni

API/
├── Endpoints.swift    # Definizioni endpoint
├── DTOs.swift         # Data Transfer Objects
└── Decoders.swift     # JSON decoders custom
```

### ConversationsRepository Protocol

```swift
protocol ConversationsRepository {
    func fetchModels() async throws -> [ChatModel]
    func listConversations(limit: Int, cursor: String?) async throws 
        -> (items: [Conversation], nextCursor: String?)
    func getConversation(id: UUID) async throws -> Conversation
    func getMessages(conversationId: UUID, limit: Int, cursor: String?) async throws 
        -> (items: [Message], nextCursor: String?)
    func createConversation(initialMessage: Message?, modelId: String) async throws 
        -> Conversation
    func updateConversation(id: UUID, title: String?, modelId: String?, isPinned: Bool?) async throws 
        -> Conversation
    func deleteConversation(id: UUID) async throws
    func duplicateConversation(id: UUID) async throws -> Conversation
    func sendMessage(conversationId: UUID, text: String) async throws -> URLRequest
}
```

### Implementazioni

#### RemoteConversationsRepository

Implementazione che comunica con backend Python:

```swift
final class RemoteConversationsRepository: ConversationsRepository {
    private let client: HTTPClient
    
    func listConversations(limit: Int, cursor: String?) async throws 
        -> (items: [Conversation], nextCursor: String?) {
        let endpoint = Endpoints.listConversations(limit: limit, cursor: cursor)
        let response: ConversationListResponse = try await client.request(endpoint)
        let conversations = response.items.map { $0.toDomain() }
        return (items: conversations, nextCursor: response.nextCursor)
    }
    // ... altre implementazioni
}
```

#### MockConversationsStore

Implementazione mock per sviluppo:

```swift
final class MockConversationsStore: ConversationsUIStore {
    private var conversations: [Conversation] = []
    var availableModels: [ChatModel] = [
        ChatModel(id: "gpt-4", displayName: "GPT-4", description: "..."),
        // ...
    ]
    
    func fetchConversations() -> [Conversation] { conversations }
    // ... metodi sincroni per testing rapido
}
```

### API Layer

#### Endpoints.swift

Definizioni type-safe degli endpoint:

```swift
enum Endpoints {
    static func listModels() -> Endpoint {
        Endpoint(path: "/models", method: .GET)
    }
    
    static func listConversations(limit: Int, cursor: String?) -> Endpoint {
        var query: [URLQueryItem] = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let cursor = cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(path: "/conversations", method: .GET, query: query)
    }
    // ... altri endpoint
}
```

#### DTOs.swift

Data Transfer Objects per JSON:

```swift
struct ConversationDTO: Codable {
    let id: String
    let title: String
    let modelId: String
    let isPinned: Bool
    let createdAt: String
    let updatedAt: String
    
    func toDomain() -> Conversation {
        Conversation(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            modelId: modelId,
            isPinned: isPinned,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            updatedAt: ISO8601DateFormatter().date(from: updatedAt) ?? Date()
        )
    }
}
```

## Layer 5: Network Layer

### Responsabilità

Il Network Layer gestisce:
- Richieste HTTP
- Streaming Server-Sent Events
- Serializzazione/deserializzazione
- Gestione errori di rete

### HTTPClient.swift

Client HTTP generico:

```swift
struct HTTPClient {
    let baseURL: URL
    let session: URLSession
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // 1. Costruisce URL
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), 
                                          resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = endpoint.query
        
        guard let url = urlComponents?.url else {
            throw HTTPError.invalidURL
        }
        
        // 2. Crea URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // 3. Aggiunge headers
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // 4. Aggiunge body se presente
        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // 5. Esegue richiesta
        let (data, response) = try await session.data(for: request)
        
        // 6. Valida risposta
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // 7. Decodifica
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HTTPError.decodingError(error)
        }
    }
}
```

### SSEClient.swift

Client per Server-Sent Events:

```swift
final class SSEClient {
    private let session: URLSession
    
    func stream(urlRequest: URLRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = urlRequest
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    // Valida risposta
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: SSEError.invalidResponse)
                        return
                    }
                    
                    // Legge stream byte per byte
                    var buffer = ""
                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))
                        
                        if char == "\n" {
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
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: SSEError.networkError(error))
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
```

## Comunicazione tra i Layer

### Regole di Dipendenza

1. **Layer superiori dipendono da layer inferiori**, mai il contrario
2. **Dipendenze verso astrazioni**: Es. UIState dipende da ConversationsRepository (protocollo), non da RemoteConversationsRepository
3. **No skip di layer**: UI non comunica direttamente con Network Layer
4. **Iniezione delle dipendenze**: Tramite initializer

### Esempio di Flusso Completo

Scenario: L'utente invia un messaggio

```
1. ComposerView (UI)
   ↓ onSubmit
2. UIState.sendMessage()
   ↓ async call
3. ChatService.streamReply()
   ↓ richiede URLRequest
4. ConversationsRepository.sendMessage()
   ↓ costruisce endpoint
5. HTTPClient (implicito nel repository per preparare request)
   ↓ SSEClient riceve URLRequest
6. SSEClient.stream()
   ↓ AsyncThrowingStream
7. ChatService (riceve eventi)
   ↓ callback onDelta
8. UIState (accumula testo)
   ↓ @Published update
9. MessageRowView (UI si aggiorna)
```

## Vantaggi di Questa Architettura

1. **Separazione delle Responsabilità**: Ogni layer ha un ruolo chiaro
2. **Testabilità**: Ogni layer può essere testato indipendentemente
3. **Manutenibilità**: Modifiche localizzate a un layer
4. **Scalabilità**: Facile aggiungere nuove funzionalità
5. **Riusabilità**: Componenti ben isolati riutilizzabili
6. **Type Safety**: Forte tipizzazione in tutti i layer

## Conclusione

L'architettura a layer dell'applicazione GPT fornisce una struttura solida, manutenibile e scalabile. La separazione netta delle responsabilità e l'uso di pattern consolidati rendono il codice facile da comprendere, testare ed estendere.
