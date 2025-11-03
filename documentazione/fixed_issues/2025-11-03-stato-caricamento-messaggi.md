# FIX: Stato di caricamento messaggi (SwiftUI data flow)

- Data: 2025-11-03
- Componenti: `UIState`, `ChatView`, `MessageRowView`, `ComposerView`, `AppConstants`

## Obiettivo

- Mostrare subito feedback visivo quando l’utente invia un messaggio:
  - messaggio dell’assistente in stato `pending` fino a streaming/errore;
  - indicatori coerenti nel bubble e nel composer;
  - messaggio d’errore amichevole e banner globale se il backend non risponde.
  - messaggio di errore se impossibilità di comunicazione con il backend python.

## Sintesi della soluzione

- `ChatView` è disaccoppiata: accetta `conversationID` e legge i dati da `@EnvironmentObject UIState`.
- Backend remoto attivo di default (`useRemoteBackend = true`).
- Invio remoto crea sempre una conversazione provvisoria con un messaggio assistente `.pending`.
- In caso di successo, la conversazione remota sincronizzata sostituisce quella provvisoria, preservando il placeholder; durante lo streaming il placeholder passa a `.streaming`, poi `.complete`.
- In caso di errore (rete/API), il placeholder rimane e viene promosso a `.error(<messaggio amichevole>)` e appare anche un banner globale.

## Perché prima non funzionava

- App avviata in mock locale (backend remoto disattivo): il flusso locale non creava alcun placeholder dell’assistente, quindi nessuno stato di caricamento.
- Su errore nella creazione remota, la conversazione provvisoria veniva scartata lasciando la UI vuota, impedendo uno stato `pending` persistente/errore contestuale.

## Riferimenti essenziali nel codice

Default backend remoto attivo:
```5:7:/Users/andreabollato/Documents/Coding/Swift/GPT/frontendMacOS/Design/AppConstants.swift
static let baseURL = "http://127.0.0.1:8000"
static let useRemoteBackend = true // Set to false to fall back to dati locali mock
```

`ChatView` usa `conversationID` e legge da `UIState` tramite environment:
```3:13:/Users/andreabollato/Documents/Coding/Swift/GPT/frontendMacOS/Views/Chat/ChatView.swift
struct ChatView: View {
    @EnvironmentObject private var uiState: UIState
    let conversationID: UUID

    private var conversation: Conversation? {
        uiState.conversation(with: conversationID)
    }
```

Placeholder `.pending`, sincronizzazione, streaming ed esiti:
```286:306:/Users/andreabollato/Documents/Coding/Swift/GPT/frontendMacOS/ViewModels/UIState.swift
let userMessage = Message(role: .user, text: text, status: .complete)
let placeholderMessage = Message(role: .assistant, text: "", status: .pending)
...
if let existingId = conversationID, ... {
    ...
    conversation.messages.append(userMessage)
    conversation.messages.append(placeholderMessage)
} else if isNewConversation {
    if conversationID == nil { setPendingPhase(.sending) }
    ...
    var provisionalConversation = Conversation(
        id: UUID(),
        title: provisionalTitle(from: text),
        modelId: activeModelId,
        messages: [userMessage, placeholderMessage]
    )
    updateLocal(provisionalConversation)
    selectedConversationID = provisionalConversation.id
    setPhase(.sending, for: provisionalConversation.id)
}
```

Streaming e completamento:
```380:400:/Users/andreabollato/Documents/Coding/Swift/GPT/frontendMacOS/ViewModels/UIState.swift
setPhase(.streaming, for: convId)
await chatService.streamReply(
    conversationId: remoteId,
    userText: text,
    onDelta: { [weak self] delta in
        ... if case .pending = message.status { message.status = .streaming }
        message.text += delta
    },
    onDone: { [weak self] in
        self?.setPhase(.idle, for: convId)
        message.status = .complete
    },
```

Promozione a `.error` e banner globale:
```401:409:/Users/andreabollato/Documents/Coding/Swift/GPT/frontendMacOS/ViewModels/UIState.swift
onError: { [weak self] error in
    let friendly = self?.friendlyErrorMessage(for: error) ?? ""
    self?.setPhase(.error(message: friendly), for: convId)
    message.status = .error(friendly)
    message.text = friendly
    self?.handleError(error) // imposta uiState.errorMessage per il banner
}
```

Gestione UI dei diversi stati del messaggio (bubble):
```34:42:/Users/andreabollato/Documents/Coding/Swift/GPT/frontendMacOS/Views/Chat/MessageRowView.swift
switch message.status {
case .pending:   loadingContent
case .streaming: streamingContent
case .complete:  completeContent
case .error(let errorMessage): errorContent(text: errorMessage)
}
```

Indicatori nel composer per `sending/streaming/error`:
```128:136:/Users/andreabollato/Documents/Coding/Swift/GPT/frontendMacOS/Views/Chat/ComposerView.swift
@ViewBuilder
private var statusIndicator: some View {
    if isSendingPhase {
        progressIndicator(text: "Richiesta al servizio Python...")
    } else if isStreamingPhase {
        progressIndicator(text: "Assistente sta rispondendo...")
    } else if let errorMessage {
        errorIndicator(text: errorMessage)
    }
}
```

## Comportamento atteso (verificato)

- All’invio: compare subito un bubble dell’assistente in stato `pending`; il composer mostra “Richiesta…”.
- In streaming: il bubble passa a `streaming` e si aggiorna a delta; il composer mostra “Assistente sta rispondendo…”.
- Successo: stato `complete` e fase `.idle`.
- Errore rete/API: bubble diventa `.error(<messaggio amichevole>)` e appare il banner globale con lo stesso testo.

## Note

- Lo scroll va in fondo su nuovi messaggi/stati (`ChatView.scrollToBottom`).
- In locale (mock) il placeholder non è usato; l’esperienza completa richiede `useRemoteBackend = true`.


