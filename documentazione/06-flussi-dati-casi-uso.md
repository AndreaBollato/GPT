# Flussi di Dati e Casi d'Uso

## Introduzione

Questa sezione descrive i principali flussi di dati dell'applicazione, analizzando in dettaglio come le informazioni fluiscono attraverso i vari layer architetturali per i casi d'uso più comuni.

## Caso d'Uso 1: Avvio dell'Applicazione

### Flusso Completo

```
1. Sistema → GPTApp.main
2. GPTApp → Verifica AppConstants.API.useRemoteBackend
3. Se Remote:
   a. GPTApp → Crea HTTPClient(baseURL)
   b. GPTApp → Crea RemoteConversationsRepository(client)
   c. GPTApp → Crea ChatService(repository)
   d. GPTApp → Crea UIState(repository, chatService)
4. Se Mock:
   a. GPTApp → Crea MockConversationsStore()
   b. GPTApp → Crea UIState(store)
5. GPTApp → Mostra AppRootView(uiState)
6. AppRootView → Inietta uiState come @EnvironmentObject
7. UIState → Task { await loadInitial() }
8. UIState → Chiama repo.fetchModels()
9. Repository → HTTPClient.request(Endpoints.listModels())
10. HTTPClient → URLSession.data(for: request)
11. Backend → Risponde con JSON modelli
12. HTTPClient → Decodifica [ChatModelDTO]
13. Repository → Converte a [ChatModel]
14. UIState → @Published availableModels = models
15. UIState → Chiama repo.listConversations()
16. [Simile a fetchModels per le conversazioni]
17. UIState → @Published conversations = conversations
18. SwiftUI → Aggiorna UI automaticamente
```

### Diagramma di Sequenza

```
┌──────┐  ┌────────┐  ┌─────────┐  ┌──────────┐  ┌────────┐  ┌─────────┐
│System│  │ GPTApp │  │ UIState │  │   Repo   │  │ Client │  │ Backend │
└──┬───┘  └───┬────┘  └────┬────┘  └────┬─────┘  └───┬────┘  └────┬────┘
   │          │            │            │            │            │
   │ main()   │            │            │            │            │
   ├─────────>│            │            │            │            │
   │          │            │            │            │            │
   │          │ init()     │            │            │            │
   │          ├───────────>│            │            │            │
   │          │            │            │            │            │
   │          │            │loadInitial()│           │            │
   │          │            ├────────────>│           │            │
   │          │            │            │            │            │
   │          │            │            │request(GET /models)    │
   │          │            │            ├───────────>│           │
   │          │            │            │            │           │
   │          │            │            │            │ GET       │
   │          │            │            │            ├──────────>│
   │          │            │            │            │           │
   │          │            │            │            │ JSON      │
   │          │            │            │            │<──────────┤
   │          │            │            │            │           │
   │          │            │            │ [ChatModel]│           │
   │          │            │            │<───────────┤           │
   │          │            │            │            │           │
   │          │            │ models     │            │           │
   │          │            │<───────────┤            │           │
   │          │            │            │            │           │
   │          │  UI Update │            │            │           │
   │          │<───────────┤            │            │           │
```

### Codice Chiave

```swift
// GPTApp.swift
@main
struct GPTApp: App {
    var body: some Scene {
        WindowGroup {
            if AppConstants.API.useRemoteBackend {
                AppRootView(uiState: createRemoteUIState())
            } else {
                AppRootView()
            }
        }
    }
    
    private func createRemoteUIState() -> UIState {
        guard let baseURL = URL(string: AppConstants.API.baseURL) else {
            fatalError("Invalid base URL")
        }
        
        let client = HTTPClient(baseURL: baseURL)
        let repo = RemoteConversationsRepository(client: client)
        let chatService = ChatService(repo: repo)
        
        return UIState(repo: repo, chatService: chatService)
    }
}

// UIState.swift
init(repo: ConversationsRepository, chatService: ChatService) {
    self.repo = repo
    self.chatService = chatService
    self.store = nil
    self.activeModelId = "gpt-4"
    
    Task {
        await loadInitial()
    }
}

private func loadInitial() async {
    await loadModels()
    await loadConversations()
}
```

## Caso d'Uso 2: Creazione Nuova Conversazione

### Flusso Completo

```
1. Utente → Digita messaggio in HomeView.ComposerView
2. Utente → Preme Cmd+Enter o click su Send
3. ComposerView → onSend(text)
4. HomeView → uiState.createNewConversation(withMessage: text)
5. UIState → Imposta isLoading = true
6. UIState → repo.createConversation(initialMessage, modelId)
7. Repository → Crea CreateConversationRequest DTO
8. Repository → HTTPClient.request(Endpoints.createConversation())
9. HTTPClient → Serializza request body a JSON
10. HTTPClient → POST /conversations con body JSON
11. Backend → Crea conversazione nel database
12. Backend → Risponde con ConversationDTO JSON
13. HTTPClient → Decodifica ConversationDTO
14. Repository → Converte DTO a Conversation domain model
15. UIState → Aggiunge conversation a conversations array
16. UIState → Imposta selectedConversationID = conversation.id
17. UIState → @Published trigger update
18. SwiftUI → AppRootView mostra ChatView invece di HomeView
19. UIState → Se c'era initialMessage, invia automaticamente
20. [Procede con Caso d'Uso 3: Invio Messaggio]
```

### Diagramma di Sequenza

```
┌──────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐ ┌─────────┐
│ User │ │Composer  │ │ UIState │ │   Repo   │ │ Client │ │ Backend │
└──┬───┘ └────┬─────┘ └────┬────┘ └────┬─────┘ └───┬────┘ └────┬────┘
   │         │            │            │            │            │
   │ "Hello" │            │            │            │            │
   ├────────>│            │            │            │            │
   │         │            │            │            │            │
   │         │onSend()    │            │            │            │
   │         ├───────────>│            │            │            │
   │         │            │            │            │            │
   │         │            │createConversation()    │            │
   │         │            ├────────────>│           │            │
   │         │            │            │            │            │
   │         │            │            │request(POST /conv)     │
   │         │            │            ├───────────>│           │
   │         │            │            │            │           │
   │         │            │            │            │POST+JSON  │
   │         │            │            │            ├──────────>│
   │         │            │            │            │           │
   │         │            │            │            │ JSON DTO  │
   │         │            │            │            │<──────────┤
   │         │            │            │            │           │
   │         │            │            │Conversation│           │
   │         │            │            │<───────────┤           │
   │         │            │            │            │           │
   │         │            │conversation│            │           │
   │         │            │<───────────┤            │           │
   │         │            │            │            │           │
   │         │  Navigate  │            │            │           │
   │         │<───────────┤            │            │           │
```

### Codice Chiave

```swift
// HomeView.swift
ComposerView(
    draft: $uiState.homeDraft,
    isStreaming: false,
    onSend: { text in
        uiState.createNewConversation(withMessage: text)
    },
    onStop: {}
)

// UIState.swift
func createNewConversation(withMessage text: String? = nil) async {
    isLoadingConversations = true
    
    do {
        let message = text.map { Message(role: .user, text: $0) }
        let conversation = try await repo.createConversation(
            initialMessage: message,
            modelId: activeModelId
        )
        
        await MainActor.run {
            conversations.insert(conversation, at: 0)
            selectedConversationID = conversation.id
            homeDraft = ""
            
            if text != nil {
                // Invia messaggio automaticamente
                Task {
                    await sendMessage(text!, in: conversation.id)
                }
            }
        }
    } catch {
        await MainActor.run {
            handleError(error, context: "creating conversation")
        }
    }
    
    isLoadingConversations = false
}
```

## Caso d'Uso 3: Invio Messaggio con Streaming Risposta

### Flusso Completo (Dettagliato)

```
1. Utente → Digita "Explain Swift actors" in ComposerView
2. Utente → Preme Cmd+Enter
3. ComposerView → onSend("Explain Swift actors")
4. ChatView → uiState.sendMessage(text, in: conversationId)
5. UIState → Imposta requestPhaseById[id] = .sending
6. UIState → Crea Message ottimistico (role: .user, status: .pending)
7. UIState → Aggiunge messaggio alla conversazione localmente
8. UIState → @Published trigger → UI mostra messaggio utente immediatamente
9. UIState → Crea Message assistente vuoto (role: .assistant, status: .streaming)
10. UIState → Aggiunge messaggio assistente alla conversazione
11. UIState → chatService.streamReply(conversationId, userText, callbacks)
12. ChatService → repo.sendMessage(conversationId, text)
13. Repository → Crea SendMessageRequest DTO
14. Repository → Costruisce URLRequest per POST /conversations/{id}/messages
15. Repository → Restituisce URLRequest a ChatService
16. ChatService → sseClient.stream(urlRequest)
17. SSEClient → Imposta Accept: text/event-stream header
18. SSEClient → URLSession.bytes(for: request)
19. Backend → Apre connessione SSE
20. Backend → Inizia generazione risposta AI
21. Backend → Invia evento: data: {"deltaText":"Swift","done":false}
22. SSEClient → Legge bytes, rileva "data: " prefix
23. SSEClient → Parsa JSON, crea SSEEvent
24. SSEClient → yield SSEEvent nello stream
25. ChatService → Riceve evento via for try await
26. ChatService → Estrae deltaText = "Swift"
27. ChatService → Chiama onDelta("Swift")
28. UIState → Callback ricevuto su MainActor
29. UIState → Aggiunge "Swift" al message.text
30. UIState → @Published trigger
31. SwiftUI → MessageRowView aggiorna mostrando "Swift"
32. [Ripete 21-31 per ogni delta ricevuto]
33. Backend → Invia evento: data: {"deltaText":"","done":true}
34. SSEClient → yield evento done
35. ChatService → Rileva done = true
36. ChatService → Chiama onDone()
37. UIState → Imposta message.status = .complete
38. UIState → Imposta requestPhaseById[id] = .idle
39. UIState → @Published trigger
40. SwiftUI → MessageRowView rimuove spinner "Thinking..."
```

### Diagramma di Sequenza Streaming

```
┌────┐ ┌────────┐ ┌───────┐ ┌─────────┐ ┌────────┐ ┌─────────┐ ┌─────────┐
│User│ │Composer│ │UIState│ │ ChatSvc │ │SSEClient│ │URLSession│ │ Backend │
└─┬──┘ └───┬────┘ └───┬───┘ └────┬────┘ └───┬────┘ └────┬────┘ └────┬────┘
  │        │          │          │          │          │          │
  │"Hello" │          │          │          │          │          │
  ├───────>│          │          │          │          │          │
  │        │          │          │          │          │          │
  │        │sendMsg() │          │          │          │          │
  │        ├─────────>│          │          │          │          │
  │        │          │          │          │          │          │
  │        │          │+Optimistic User Msg │          │          │
  │        │          │+Empty Assistant Msg │          │          │
  │        │          │          │          │          │          │
  │        │          │streamReply()        │          │          │
  │        │          ├─────────>│          │          │          │
  │        │          │          │          │          │          │
  │        │          │          │stream(urlReq)       │          │
  │        │          │          ├─────────>│          │          │
  │        │          │          │          │          │          │
  │        │          │          │          │bytes(req)│          │
  │        │          │          │          ├─────────>│          │
  │        │          │          │          │          │          │
  │        │          │          │          │          │POST /msg │
  │        │          │          │          │          ├─────────>│
  │        │          │          │          │          │          │
  │        │  UI Update (user msg shown)    │          │          │
  │        │<─────────┤          │          │          │          │
  │        │          │          │          │          │          │
  │        │          │          │          │          │ SSE: "S" │
  │        │          │          │          │          │<─────────┤
  │        │          │          │          │          │          │
  │        │          │          │          │SSEEvent  │          │
  │        │          │          │          │<─────────┤          │
  │        │          │          │          │          │          │
  │        │          │          │onDelta("S")         │          │
  │        │          │          │<─────────┤          │          │
  │        │          │          │          │          │          │
  │        │          │text+="S" │          │          │          │
  │        │          │<─────────┤          │          │          │
  │        │          │          │          │          │          │
  │        │  UI Update ("S")    │          │          │          │
  │        │<─────────┤          │          │          │          │
  │        │          │          │          │          │          │
  │        │          │          │          │          │SSE:"wift"│
  │        │          │          │          │          │<─────────┤
  │        │          │          │          │          │          │
  │        │          │          │onDelta("wift")      │          │
  │        │          │          │<─────────┤          │          │
  │        │          │          │          │          │          │
  │        │          │text+="wift"         │          │          │
  │        │          │<─────────┤          │          │          │
  │        │          │          │          │          │          │
  │        │  UI Update ("Swift")│          │          │          │
  │        │<─────────┤          │          │          │          │
  │        │          │          │          │          │          │
  │        │          │          │          │          │SSE: done │
  │        │          │          │          │          │<─────────┤
  │        │          │          │          │          │          │
  │        │          │          │onDone()  │          │          │
  │        │          │          │<─────────┤          │          │
  │        │          │          │          │          │          │
  │        │          │status=complete      │          │          │
  │        │          │<─────────┤          │          │          │
  │        │          │          │          │          │          │
  │        │  UI Update (remove spinner)    │          │          │
  │        │<─────────┤          │          │          │          │
```

### Codice Chiave

```swift
// UIState.swift
func sendMessage(_ text: String, in conversationId: UUID) async {
    // 1. Messaggio utente ottimistico
    let userMessage = Message(role: .user, text: text, status: .complete)
    updateConversation(id: conversationId) { conv in
        conv = conv.updatingMessages { messages in
            messages.append(userMessage)
        }
    }
    
    // 2. Messaggio assistente vuoto
    let assistantMessage = Message(role: .assistant, text: "", status: .streaming)
    let assistantId = assistantMessage.id
    
    updateConversation(id: conversationId) { conv in
        conv = conv.updatingMessages { messages in
            messages.append(assistantMessage)
        }
    }
    
    // 3. Imposta stato
    requestPhaseById[conversationId] = .streaming
    
    // 4. Avvia streaming
    await chatService?.streamReply(
        conversationId: conversationId,
        userText: text,
        onDelta: { [weak self] delta in
            guard let self = self else { return }
            
            // Accumula delta
            self.updateConversation(id: conversationId) { conv in
                conv = conv.updatingMessages { messages in
                    if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                        var msg = messages[index]
                        msg.text += delta
                        messages[index] = msg
                    }
                }
            }
        },
        onDone: { [weak self] in
            guard let self = self else { return }
            
            // Finalizza messaggio
            self.updateConversation(id: conversationId) { conv in
                conv = conv.updatingMessages { messages in
                    if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                        var msg = messages[index]
                        msg.status = .complete
                        messages[index] = msg
                    }
                }
            }
            
            self.requestPhaseById[conversationId] = .idle
        },
        onError: { [weak self] error in
            guard let self = self else { return }
            
            self.handleError(error, context: "streaming message")
            self.requestPhaseById[conversationId] = .error(message: error.localizedDescription)
        }
    )
}

// ChatService.swift
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
        
        let task = Task {
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
                await MainActor.run { onError(error) }
            }
        }
        
        await streams.register(conversationId: conversationId, task: task)
        
    } catch {
        await MainActor.run { onError(error) }
    }
}
```

## Caso d'Uso 4: Ricerca Conversazioni

### Flusso Completo

```
1. Utente → Click su search bar in SidebarView
2. SidebarView → Imposta searchFocused = true
3. Utente → Digita "Swift"
4. TextField → Binding aggiorna uiState.searchQuery = "Swift"
5. UIState → @Published searchQuery triggers update
6. SidebarView → Ricalcola pinnedConversations computed property
7. UIState.pinnedConversations → Filtra conversations per query
8. SidebarView → Ricalcola recentConversations computed property
9. UIState.recentConversations → Filtra conversations per query
10. SwiftUI → Re-render delle liste
11. ForEach → Itera solo su conversazioni filtrate
12. UI → Mostra solo conversazioni che matchano "Swift"
```

### Codice Chiave

```swift
// UIState.swift
@Published var searchQuery: String = ""

var pinnedConversations: [Conversation] {
    filteredConversations(includingPinned: true)
}

var recentConversations: [Conversation] {
    filteredConversations(includingPinned: false)
}

private func filteredConversations(includingPinned: Bool) -> [Conversation] {
    let filtered: [Conversation]
    
    if searchQuery.isEmpty {
        filtered = conversations
    } else {
        filtered = conversations.filter { conv in
            conv.title.localizedCaseInsensitiveContains(searchQuery) ||
            conv.lastMessageSnippet.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    return filtered
        .filter { includingPinned ? $0.isPinned : !$0.isPinned }
        .sorted { $0.lastActivityDate > $1.lastActivityDate }
}

// SidebarView.swift
HStack {
    Image(systemName: "magnifyingglass")
    TextField("Search...", text: $uiState.searchQuery)
        .focused($searchFocus)
}
```

## Caso d'Uso 5: Pin/Unpin Conversazione

### Flusso Completo

```
1. Utente → Click destro su ConversationRowView
2. SwiftUI → Mostra contextMenu
3. Utente → Click su "Pin" (o "Unpin")
4. ConversationRowView → uiState.togglePin(conversationId: id)
5. UIState → Imposta isLoading
6. UIState → repo.updateConversation(id, isPinned: !currentValue)
7. Repository → Crea UpdateConversationRequest DTO
8. Repository → HTTPClient.request(Endpoints.updateConversation())
9. HTTPClient → PATCH /conversations/{id} con JSON body
10. Backend → Aggiorna isPinned nel database
11. Backend → Risponde con ConversationDTO aggiornato
12. HTTPClient → Decodifica ConversationDTO
13. Repository → Converte a Conversation
14. UIState → Aggiorna conversation nell'array
15. UIState → @Published trigger
16. SidebarView → pinnedConversations/recentConversations ricalcolati
17. SwiftUI → Animazione di conversazione che si sposta tra sezioni
```

### Codice Chiave

```swift
// UIState.swift
func togglePin(conversationId: UUID) async {
    guard let conversation = conversations.first(where: { $0.id == conversationId }) else {
        return
    }
    
    let newPinState = !conversation.isPinned
    
    // Ottimistico
    updateConversation(id: conversationId) { conv in
        conv = conv.withPinned(newPinState)
    }
    
    do {
        let updated = try await repo?.updateConversation(
            id: conversationId,
            title: nil,
            modelId: nil,
            isPinned: newPinState
        )
        
        if let updated = updated {
            await MainActor.run {
                updateConversation(id: conversationId) { conv in
                    conv = updated
                }
            }
        }
    } catch {
        // Rollback ottimistico
        await MainActor.run {
            updateConversation(id: conversationId) { conv in
                conv = conv.withPinned(!newPinState)
            }
            handleError(error, context: "toggling pin")
        }
    }
}
```

## Caso d'Uso 6: Lazy Loading Messaggi

### Flusso Completo

```
1. Utente → Apre ChatView per conversazione con 100+ messaggi
2. ChatView → onAppear, UIState carica solo ultimi 30 messaggi
3. UIState → repo.getMessages(conversationId, limit: 30, cursor: nil)
4. Backend → Risponde con 30 messaggi più recenti + nextCursor
5. UIState → Aggiorna conversation.messages
6. ChatView → ScrollView mostra "Load More" button in alto
7. Utente → Scroll verso l'alto, click su "Load More"
8. ChatView → uiState.loadMoreMessages(for: conversationId)
9. UIState → repo.getMessages(conversationId, limit: 30, cursor: savedCursor)
10. Backend → Risponde con 30 messaggi precedenti + nuovo nextCursor
11. UIState → Prepende messaggi all'inizio dell'array
12. UIState → Aggiorna cursor
13. ChatView → Mostra nuovi messaggi in alto
14. [Ripete 7-13 finché hasMoreMessages = false]
```

### Codice Chiave

```swift
// UIState.swift
private var messagesCursorById: [UUID: String?] = [:]

func loadMoreMessages(for conversationId: UUID) async {
    guard let cursor = messagesCursorById[conversationId] ?? nil else {
        return  // No more messages
    }
    
    do {
        let (items, nextCursor) = try await repo?.getMessages(
            conversationId: conversationId,
            limit: 30,
            cursor: cursor
        ) ?? ([], nil)
        
        await MainActor.run {
            updateConversation(id: conversationId) { conv in
                conv = conv.updatingMessages { messages in
                    // Prepend older messages
                    messages.insert(contentsOf: items, at: 0)
                }
            }
            
            messagesCursorById[conversationId] = nextCursor
        }
    } catch {
        await MainActor.run {
            handleError(error, context: "loading more messages")
        }
    }
}

func hasMoreMessages(for conversationId: UUID) -> Bool {
    messagesCursorById[conversationId] != nil
}

// ChatView.swift
if uiState.hasMoreMessages(for: conversationID) {
    Button("Load More") {
        Task {
            await uiState.loadMoreMessages(for: conversationID)
        }
    }
}
```

## Pattern Comuni nei Flussi

### 1. Pattern Ottimistico

Aggiorna UI immediatamente, poi sincronizza con backend:

```swift
// 1. Update locale ottimistico
localUpdate()

// 2. Richiesta backend
do {
    let result = try await backendUpdate()
    // 3. Conferma con risultato backend
    confirmUpdate(result)
} catch {
    // 4. Rollback in caso di errore
    rollbackUpdate()
    handleError(error)
}
```

### 2. Pattern Async/Await con MainActor

Operazioni asincrone che aggiornano UI:

```swift
Task {
    // Background thread
    let result = try await fetchData()
    
    // Torna a Main thread per UI update
    await MainActor.run {
        self.data = result
    }
}
```

### 3. Pattern Callback con Streaming

Gestione eventi continui:

```swift
await service.stream(
    onEvent: { event in
        // Processa ogni evento
        processEvent(event)
    },
    onDone: {
        // Cleanup
        finalize()
    },
    onError: { error in
        // Gestione errore
        handle(error)
    }
)
```

### 4. Pattern Repository con DTO Mapping

Separazione tra layer di rete e dominio:

```swift
// Repository
func fetchData() async throws -> DomainModel {
    let endpoint = Endpoints.getData()
    let dto: DataDTO = try await client.request(endpoint)
    return dto.toDomain()
}

// DTO
struct DataDTO: Codable {
    let id: String
    let name: String
    
    func toDomain() -> DomainModel {
        DomainModel(
            id: UUID(uuidString: id) ?? UUID(),
            name: name
        )
    }
}
```

## Gestione Errori nei Flussi

### Propagazione Errori

```
Network Error
    ↓
HTTPClient throws HTTPError
    ↓
Repository propagates error
    ↓
UIState catches in do-catch
    ↓
UIState.handleError() sets errorMessage
    ↓
AppRootView shows ErrorBanner
    ↓
User sees error + auto-dismiss
```

### Codice

```swift
// UIState.swift
private func handleError(_ error: Error, context: String) {
    let message: String
    
    if let httpError = error as? HTTPError {
        message = "[\(context)] \(httpError.localizedDescription)"
    } else if let sseError = error as? SSEError {
        message = "[\(context)] \(sseError.localizedDescription)"
    } else {
        message = "[\(context)] \(error.localizedDescription)"
    }
    
    errorMessage = message
    
    // Auto-dismiss gestito da ErrorBanner
}
```

## Conclusione

I flussi di dati nell'applicazione GPT seguono pattern chiari e consistenti:

1. **UI → UIState → Service/Repo → Network → Backend**
2. **Aggiornamenti ottimistici** per reattività
3. **Async/await** per operazioni asincrone
4. **Callbacks/Stream** per eventi continui
5. **@Published** per reattività UI automatica
6. **Error propagation** con gestione a ogni livello

Questa architettura garantisce codice leggibile, manutenibile e performante.
