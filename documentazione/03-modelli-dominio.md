# Modelli di Dominio e Strutture Dati

## Introduzione

Questa sezione descrive in dettaglio i modelli di dominio dell'applicazione, ovvero le strutture dati che rappresentano i concetti fondamentali del sistema. I modelli sono progettati per essere immutabili, type-safe e facilmente serializzabili.

## Filosofia di Design dei Modelli

### Principi Adottati

1. **Value Semantics**: I modelli sono `struct` (value types) quando possibile
2. **Immutabilità**: Metodi che "modificano" restituiscono nuove copie
3. **Type Safety**: Uso di enums per stati e ruoli
4. **Codable**: Supporto nativo per JSON serialization/deserialization
5. **Identifiable**: Conformità a Identifiable per SwiftUI
6. **Hashable**: Conformità a Hashable per performance in collezioni

### Struttura dei File

```
Models/
├── Conversation.swift    # Modello conversazione + ChatModel
└── Message.swift         # Modello messaggio + MessageRole
```

## ChatModel

### Definizione

```swift
struct ChatModel: Identifiable, Hashable, Codable {
    var id: String
    var displayName: String
    var description: String
}
```

### Descrizione

`ChatModel` rappresenta un modello di intelligenza artificiale disponibile per le conversazioni.

### Properties

- **id**: Identificatore univoco del modello (es. "gpt-4", "gpt-3.5-turbo")
- **displayName**: Nome visualizzato nell'interfaccia (es. "GPT-4")
- **description**: Descrizione testuale del modello

### Esempi di Modelli

```swift
let gpt4 = ChatModel(
    id: "gpt-4",
    displayName: "GPT-4",
    description: "Most capable model, best for complex tasks"
)

let gpt35 = ChatModel(
    id: "gpt-3.5-turbo",
    displayName: "GPT-3.5 Turbo",
    description: "Fast and efficient for most tasks"
)
```

### Utilizzo

I modelli sono:
1. Caricati dal backend o dal mock store all'avvio
2. Memorizzati in `UIState.availableModels`
3. Selezionabili dall'utente tramite `ModelPickerView`
4. Associati a ogni conversazione tramite `Conversation.modelId`

## Conversation

### Definizione

```swift
struct Conversation: Identifiable, Hashable, Codable {
    var id: UUID
    var title: String
    var modelId: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    var messages: [Message]
}
```

### Descrizione

`Conversation` rappresenta una conversazione completa con tutti i suoi messaggi e metadati.

### Properties

#### id: UUID
- Identificatore univoco della conversazione
- Generato automaticamente se non specificato
- Usato per riferimenti e operazioni CRUD

#### title: String
- Titolo della conversazione mostrato nella sidebar
- Generalmente basato sul primo messaggio o impostato dall'utente
- Esempio: "Spiegazione dell'architettura Clean"

#### modelId: String
- Riferimento al modello AI usato (es. "gpt-4")
- Deve corrispondere a un id in `availableModels`
- Può essere cambiato durante la conversazione

#### isPinned: Bool
- Indica se la conversazione è fissata in alto nella lista
- Le conversazioni pinnate appaiono prima delle altre
- Toggle tramite UI o API

#### createdAt: Date
- Timestamp di creazione della conversazione
- Impostato automaticamente alla creazione
- Non modificabile

#### updatedAt: Date
- Timestamp dell'ultima modifica
- Aggiornato automaticamente con ogni modifica
- Usato per ordinamento

#### messages: [Message]
- Array di tutti i messaggi nella conversazione
- Ordinati cronologicamente
- Caricati lazy dal backend (paginati)

### Computed Properties

#### lastMessage: Message?

```swift
var lastMessage: Message? {
    messages.last
}
```

Restituisce l'ultimo messaggio della conversazione, o `nil` se vuota.

#### lastMessageSnippet: String

```swift
var lastMessageSnippet: String {
    guard let message = lastMessage else { return "" }
    return message.text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\n", with: " ")
}
```

Restituisce un estratto dell'ultimo messaggio, sanitizzato per la visualizzazione in una riga.

#### lastActivityDate: Date

```swift
var lastActivityDate: Date {
    lastMessage?.createdAt ?? updatedAt
}
```

Restituisce la data dell'ultima attività (ultimo messaggio o ultima modifica).

### Metodi di Aggiornamento

Siccome `Conversation` è uno struct (value type), i metodi di "modifica" restituiscono nuove istanze:

#### updatingMessages

```swift
func updatingMessages(_ transform: (inout [Message]) -> Void) -> Conversation {
    var copy = self
    transform(&copy.messages)
    copy.updatedAt = Date()
    return copy
}
```

Permette di modificare i messaggi con una closure:

```swift
let updated = conversation.updatingMessages { messages in
    messages.append(newMessage)
}
```

#### updatingTitle

```swift
func updatingTitle(_ title: String) -> Conversation {
    var copy = self
    copy.title = title
    copy.updatedAt = Date()
    return copy
}
```

Restituisce una copia con il titolo aggiornato:

```swift
let renamed = conversation.updatingTitle("Nuovo Titolo")
```

#### updatingModel

```swift
func updatingModel(_ modelId: String) -> Conversation {
    var copy = self
    copy.modelId = modelId
    copy.updatedAt = Date()
    return copy
}
```

Restituisce una copia con un nuovo modello:

```swift
let withGPT4 = conversation.updatingModel("gpt-4")
```

#### withPinned

```swift
func withPinned(_ isPinned: Bool) -> Conversation {
    var copy = self
    copy.isPinned = isPinned
    copy.updatedAt = Date()
    return copy
}
```

Restituisce una copia con stato pinned modificato:

```swift
let pinned = conversation.withPinned(true)
```

### Esempio d'Uso

```swift
// Creazione
var conversation = Conversation(
    title: "Discussione su Swift",
    modelId: "gpt-4",
    isPinned: false
)

// Aggiunta messaggio
let userMessage = Message(role: .user, text: "Cos'è un Actor?")
conversation = conversation.updatingMessages { messages in
    messages.append(userMessage)
}

// Pin della conversazione
conversation = conversation.withPinned(true)

// Cambio modello
conversation = conversation.updatingModel("gpt-3.5-turbo")
```

## MessageRole

### Definizione

```swift
enum MessageRole: String, Codable, CaseIterable, Hashable {
    case user
    case assistant
    case system
}
```

### Descrizione

Enum che rappresenta il ruolo di chi ha inviato il messaggio.

### Cases

- **user**: Messaggio inviato dall'utente umano
- **assistant**: Risposta generata dall'AI
- **system**: Messaggio di sistema (istruzioni, context, ecc.)

### Computed Properties

#### isUser / isAssistant

```swift
var isUser: Bool { self == .user }
var isAssistant: Bool { self == .assistant }
```

Helper per verificare rapidamente il ruolo.

#### displayName

```swift
var displayName: String {
    switch self {
    case .user: return "You"
    case .assistant: return "ChatGPT"
    case .system: return "System"
    }
}
```

Nome visualizzato nella UI.

## Message

### Definizione

```swift
struct Message: Identifiable, Hashable, Codable {
    enum Status: Hashable, Codable {
        case pending
        case streaming
        case complete
        case error(String)
    }
    
    var id: UUID
    var role: MessageRole
    var text: String
    var status: Status
    var createdAt: Date
    var isPinned: Bool
    var isEdited: Bool
}
```

### Descrizione

`Message` rappresenta un singolo messaggio in una conversazione.

### Properties

#### id: UUID
- Identificatore univoco del messaggio
- Generato automaticamente
- Usato per rendering efficiente in SwiftUI Lists

#### role: MessageRole
- Ruolo del mittente (user, assistant, system)
- Determina lo stile di visualizzazione
- Esempio: `.user`, `.assistant`

#### text: String
- Contenuto testuale del messaggio
- Può includere markdown
- Supporta multiline

#### status: Message.Status
- Stato corrente del messaggio
- Gestisce il ciclo di vita dalla creazione al completamento
- Vedi dettagli nella sezione Status

#### createdAt: Date
- Timestamp di creazione
- Usato per ordinamento
- Mostrato nella UI

#### isPinned: Bool
- Indica se il messaggio è fissato (feature futura)
- Attualmente non implementato nella UI
- Presente per estensibilità

#### isEdited: Bool
- Indica se il messaggio è stato modificato
- Attualmente non implementato nella UI
- Presente per estensibilità

### Message.Status

Enum annidato che rappresenta lo stato di un messaggio:

#### pending
Il messaggio è in coda per l'invio al backend.

```swift
let message = Message(role: .user, text: "Hello", status: .pending)
```

#### streaming
Il messaggio assistente sta ricevendo testo in streaming.

```swift
var message = Message(role: .assistant, text: "", status: .streaming)
// Durante lo streaming:
message.text += "Hello "
message.text += "World"
```

#### complete
Il messaggio è completo e finalizzato.

```swift
let message = Message(role: .assistant, text: "Hello World", status: .complete)
```

#### error(String)
Si è verificato un errore con questo messaggio.

```swift
let message = Message(
    role: .assistant, 
    text: "", 
    status: .error("Network timeout")
)
```

### Esempio d'Uso

```swift
// Messaggio utente
let userMessage = Message(
    role: .user,
    text: "Spiegami cos'è SwiftUI",
    status: .complete
)

// Messaggio assistente in streaming
var assistantMessage = Message(
    role: .assistant,
    text: "",
    status: .streaming
)

// Accumulo testo durante streaming
assistantMessage.text += "SwiftUI è "
assistantMessage.text += "un framework "
assistantMessage.text += "dichiarativo..."

// Finalizzazione
assistantMessage.status = .complete

// Messaggio di errore
let errorMessage = Message(
    role: .assistant,
    text: "",
    status: .error("Connection lost")
)
```

## Relazioni tra i Modelli

### Gerarchia

```
UIState
  ├── availableModels: [ChatModel]
  └── conversations: [Conversation]
        ├── modelId -> ChatModel.id
        └── messages: [Message]
              └── role: MessageRole
                    └── status: Message.Status
```

### Diagramma ER

```
┌─────────────────┐
│   ChatModel     │
│                 │
│ + id            │◄─────┐
│ + displayName   │      │
│ + description   │      │ modelId
└─────────────────┘      │
                         │
┌─────────────────────────┼────────────┐
│   Conversation          │            │
│                         │            │
│ + id                    │            │
│ + title                 │            │
│ + modelId ──────────────┘            │
│ + isPinned                           │
│ + createdAt                          │
│ + updatedAt                          │
│ + messages ─────────┐                │
└─────────────────────┼────────────────┘
                      │
                      │ 1:N
                      ▼
        ┌─────────────────────┐
        │   Message           │
        │                     │
        │ + id                │
        │ + role ──────┐      │
        │ + text        │     │
        │ + status      │     │
        │ + createdAt   │     │
        │ + isPinned    │     │
        │ + isEdited    │     │
        └───────────────┼─────┘
                        │
                        ▼
              ┌─────────────────┐
              │  MessageRole    │
              │                 │
              │ • user          │
              │ • assistant     │
              │ • system        │
              └─────────────────┘
```

## Serializzazione JSON

### Conversation ↔ ConversationDTO

#### Backend → App (Deserializzazione)

```swift
// JSON dal backend
{
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "title": "Discussione Swift",
    "modelId": "gpt-4",
    "isPinned": false,
    "createdAt": "2025-11-03T14:00:00Z",
    "updatedAt": "2025-11-03T15:30:00Z"
}

// Conversione a Conversation
let dto = try JSONDecoder().decode(ConversationDTO.self, from: jsonData)
let conversation = dto.toDomain()
```

#### App → Backend (Serializzazione)

```swift
// Conversation
let conversation = Conversation(
    id: UUID(),
    title: "Nuova Chat",
    modelId: "gpt-4",
    isPinned: false
)

// Conversione a DTO
let dto = ConversationDTO(from: conversation)
let jsonData = try JSONEncoder().encode(dto)
```

### Message ↔ MessageDTO

Simile per i messaggi:

```swift
// JSON
{
    "id": "456e4567-e89b-12d3-a456-426614174111",
    "role": "user",
    "text": "Hello!",
    "createdAt": "2025-11-03T15:00:00Z"
}

// Conversione
let dto = try JSONDecoder().decode(MessageDTO.self, from: jsonData)
let message = dto.toDomain()
```

## Pattern e Best Practices

### 1. Immutabilità

```swift
// ❌ Non fare
conversation.title = "New Title"  // Modifica diretta

// ✅ Fare
let updated = conversation.updatingTitle("New Title")
```

### 2. Metodi di Trasformazione

```swift
// Pattern fluent
let result = conversation
    .withPinned(true)
    .updatingTitle("Important")
    .updatingModel("gpt-4")
```

### 3. Value Semantics

```swift
var conv1 = conversation
var conv2 = conv1  // Copia, non riferimento

conv2 = conv2.updatingTitle("New")
// conv1.title rimane invariato
```

### 4. Optional Handling

```swift
// Accesso sicuro all'ultimo messaggio
if let last = conversation.lastMessage {
    print(last.text)
}

// Con nil-coalescing
let snippet = conversation.lastMessageSnippet
```

### 5. Codable per Persistence

```swift
// Salva conversazione
let data = try JSONEncoder().encode(conversation)
UserDefaults.standard.set(data, forKey: "lastConversation")

// Carica conversazione
if let data = UserDefaults.standard.data(forKey: "lastConversation") {
    let conversation = try JSONDecoder().decode(Conversation.self, from: data)
}
```

## Estendibilità dei Modelli

### Aggiungere un Nuovo Campo

Esempio: aggiungere `tags` a Conversation

```swift
struct Conversation: Identifiable, Hashable, Codable {
    // ... campi esistenti
    var tags: [String] = []  // Nuovo campo con default
    
    // Metodo helper
    func addingTag(_ tag: String) -> Conversation {
        var copy = self
        copy.tags.append(tag)
        copy.updatedAt = Date()
        return copy
    }
}
```

### Aggiungere un Nuovo MessageRole

```swift
enum MessageRole: String, Codable, CaseIterable, Hashable {
    case user
    case assistant
    case system
    case function  // Nuovo ruolo per function calling
    
    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "ChatGPT"
        case .system: return "System"
        case .function: return "Function"  // Nuovo caso
        }
    }
}
```

## Conclusione

I modelli di dominio dell'applicazione GPT sono progettati per essere:

- **Type-safe**: Sfruttano il type system di Swift
- **Immutabili**: Prevenendo bug da side-effects
- **Serializzabili**: Per comunicazione con backend e persistence
- **Componibili**: Facilmente estendibili e modificabili
- **SwiftUI-friendly**: Conformi a Identifiable, Hashable, ecc.

Questa struttura solida fornisce le fondamenta per un'applicazione robusta e manutenibile.
