# Documentazione Completa - Applicazione GPT per macOS

## Benvenuti

Questa è la documentazione completa dell'applicazione GPT, un client nativo macOS sviluppato in SwiftUI per interagire con modelli di intelligenza artificiale conversazionale. La documentazione è organizzata per guidarvi attraverso tutti gli aspetti dell'applicazione, dall'architettura generale ai dettagli implementativi.

## Struttura della Documentazione

### [01. Panoramica Generale](01-panoramica-generale.md)
**Cosa troverete**: Introduzione all'applicazione, scopo, architettura di alto livello, componenti principali e caratteristiche distintive.

**Adatto per**: 
- Manager e stakeholder che vogliono capire cosa fa l'applicazione
- Nuovi sviluppatori che iniziano a lavorare sul progetto
- Chiunque voglia una visione d'insieme prima di approfondire

**Argomenti chiave**:
- Scopo dell'applicazione
- Architettura a livelli
- Panoramica dei componenti principali
- Flusso di dati generale
- Modalità di funzionamento (Mock vs Backend)
- Tecnologie e pattern utilizzati

### [02. Architettura dei Layer](02-architettura-layer.md)
**Cosa troverete**: Descrizione dettagliata dell'architettura a layer, responsabilità di ogni layer, componenti specifici e come comunicano tra loro.

**Adatto per**:
- Sviluppatori che devono estendere o modificare l'applicazione
- Architetti software che vogliono comprendere le scelte architetturali
- Chi deve fare refactoring o manutenzione

**Argomenti chiave**:
- Presentation Layer (Views SwiftUI)
- State Management Layer (UIState)
- Business Logic Layer (Services)
- Data Access Layer (Repositories + API)
- Network Layer (HTTPClient + SSEClient)
- Regole di dipendenza tra layer

### [03. Modelli di Dominio e Strutture Dati](03-modelli-dominio.md)
**Cosa troverete**: Descrizione completa dei modelli dati che rappresentano i concetti del dominio: Conversation, Message, ChatModel, ecc.

**Adatto per**:
- Sviluppatori che lavorano con i dati
- Chi deve integrare con il backend
- Chi deve estendere i modelli con nuovi campi

**Argomenti chiave**:
- ChatModel: modelli AI disponibili
- Conversation: struttura conversazioni
- Message e MessageRole: messaggi e ruoli
- Message.Status: stati dei messaggi
- Serializzazione JSON (DTOs)
- Pattern di immutabilità
- Metodi di trasformazione

### [04. Interfaccia Utente e Componenti SwiftUI](04-interfaccia-utente.md)
**Cosa troverete**: Descrizione dettagliata di tutte le viste SwiftUI, composizione dell'interfaccia, gestione dello stato UI, animazioni.

**Adatto per**:
- Sviluppatori frontend/UI
- Designer che vogliono capire l'implementazione
- Chi deve aggiungere nuove viste o modificare l'UI esistente

**Argomenti chiave**:
- AppRootView: struttura radice
- SidebarView: lista conversazioni
- ChatView: vista chat principale
- HomeView: schermata iniziale
- Componenti condivisi (MessageRow, Composer, ErrorBanner, ecc.)
- Gestione dello stato con @EnvironmentObject
- Pattern di composizione SwiftUI
- Animazioni e transizioni
- Design system (colori, tipografia, spacing)

### [05. Networking e Comunicazione con il Backend](05-networking-backend.md)
**Cosa troverete**: Descrizione completa del layer di networking, HTTPClient, SSEClient, gestione errori, contratto API.

**Adatto per**:
- Sviluppatori backend che devono implementare l'API
- Sviluppatori frontend che lavorano con networking
- Chi deve debuggare problemi di comunicazione
- DevOps che configurano l'infrastruttura

**Argomenti chiave**:
- HTTPClient: richieste REST
- SSEClient: streaming Server-Sent Events
- Endpoints: definizioni type-safe
- DTOs: Data Transfer Objects
- Contratto API completo con esempi
- Gestione errori di rete
- Async/await e concorrenza
- Best practices networking

### [06. Flussi di Dati e Casi d'Uso](06-flussi-dati-casi-uso.md)
**Cosa troverete**: Analisi dettagliata dei principali flussi di dati attraverso l'applicazione con diagrammi di sequenza e esempi di codice.

**Adatto per**:
- Sviluppatori che devono capire come funziona end-to-end
- Chi deve debuggare problemi complessi
- Chi vuole imparare i pattern utilizzati

**Argomenti chiave**:
- Avvio applicazione
- Creazione nuova conversazione
- Invio messaggio con streaming risposta
- Ricerca conversazioni
- Pin/Unpin conversazioni
- Lazy loading messaggi
- Pattern comuni (ottimistico, async/await, callbacks)
- Gestione errori nei flussi

### [07. API Endpoints - Riferimento Completo](07-api-endpoints.md)
**Cosa troverete**: Documentazione completa di tutti gli endpoint API con URL, metodi HTTP, parametri, request body, response format e esempi pratici.

**Adatto per**:
- Sviluppatori backend che implementano l'API
- Sviluppatori frontend che integrano le API
- Team di testing per creare test di integrazione
- DevOps per configurazione e deployment

**Argomenti chiave**:
- Tutti gli endpoint API (Models, Conversations, Messages)
- URL completi e metodi HTTP
- Formato richieste (query params, body JSON)
- Formato risposte con esempi reali
- Server-Sent Events (SSE) per streaming
- Gestione errori e status codes
- Paginazione con cursori
- Best practices implementazione backend
- Esempi completi di flussi API

## Come Utilizzare questa Documentazione

### Per Nuovi Sviluppatori

1. **Iniziate con** [01. Panoramica Generale](01-panoramica-generale.md) per capire cosa fa l'applicazione
2. **Proseguite con** [02. Architettura dei Layer](02-architettura-layer.md) per comprendere la struttura
3. **Approfondite** i documenti specifici in base al vostro ruolo:
   - UI/Frontend → [04. Interfaccia Utente](04-interfaccia-utente.md)
   - Backend → [05. Networking](05-networking-backend.md)
   - Data/Models → [03. Modelli di Dominio](03-modelli-dominio.md)
4. **Consultate** [06. Flussi di Dati](06-flussi-dati-casi-uso.md) per capire come tutto funziona insieme

### Per Sviluppatori Esperti

1. **Referenza rapida**: Consultate il documento specifico per l'area su cui state lavorando
2. **Debugging**: [06. Flussi di Dati](06-flussi-dati-casi-uso.md) con i diagrammi di sequenza
3. **Estensioni**: [02. Architettura](02-architettura-layer.md) per capire dove aggiungere nuove feature
4. **API Integration**: [07. API Endpoints](07-api-endpoints.md) per il riferimento completo degli endpoint

### Per Backend Developers

1. **Iniziate con** [07. API Endpoints](07-api-endpoints.md) per il riferimento completo di tutti gli endpoint
2. **Alternative**: [05. Networking](05-networking-backend.md) per il contratto API con contesto architetturale
3. **Consultate** [03. Modelli di Dominio](03-modelli-dominio.md) per le strutture dati
4. **Verificate** [06. Flussi di Dati](06-flussi-dati-casi-uso.md) per comprendere come vengono usate le API

### Per Designer/UX

1. **Visione generale**: [01. Panoramica Generale](01-panoramica-generale.md)
2. **Dettagli UI**: [04. Interfaccia Utente](04-interfaccia-utente.md)
3. **Interazioni**: [06. Flussi di Dati](06-flussi-dati-casi-uso.md) per capire i casi d'uso

## Convenzioni Usate nella Documentazione

### Codice

I blocchi di codice sono formattati così:

```swift
struct Example: View {
    var body: some View {
        Text("Hello")
    }
}
```

### Diagrammi di Architettura

```
┌─────────────┐
│   Layer 1   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Layer 2   │
└─────────────┘
```

### Diagrammi di Sequenza

```
┌──────┐  ┌──────┐
│Client│  │Server│
└──┬───┘  └───┬──┘
   │ Request  │
   ├─────────>│
   │          │
   │ Response │
   │<─────────┤
```

### Flussi

```
1. Passo 1
2. Passo 2
   a. Sub-passo
   b. Sub-passo
3. Passo 3
```

## Struttura del Codice

L'applicazione è organizzata in questa struttura di cartelle:

```
GPT/
├── GPTApp.swift                  # Entry point
├── ContentView.swift             # Vista di default
│
├── Models/                       # Modelli di dominio
│   ├── Conversation.swift
│   └── Message.swift
│
├── Views/                        # Interfaccia utente SwiftUI
│   ├── AppRootView.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   ├── ComposerView.swift
│   │   ├── MessageRowView.swift
│   │   └── ModelPickerView.swift
│   ├── Sidebar/
│   │   ├── SidebarView.swift
│   │   └── ConversationRowView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   └── Shared/
│       ├── AvatarView.swift
│       ├── CodeBlockView.swift
│       ├── ErrorBanner.swift
│       ├── MarkdownMessageView.swift
│       └── TopBarView.swift
│
├── ViewModels/                   # State management
│   └── UIState.swift
│
├── Services/                     # Business logic
│   ├── ChatService.swift
│   └── StreamingCenter.swift
│
├── Repositories/                 # Data access
│   └── ConversationsRepository.swift
│
├── API/                          # API layer
│   ├── Endpoints.swift
│   ├── DTOs.swift
│   └── Decoders.swift
│
├── Networking/                   # Network layer
│   ├── HTTPClient.swift
│   └── SSEClient.swift
│
└── Design/                       # Design system
    ├── AppColors.swift
    ├── AppTypography.swift
    ├── AppButtonStyles.swift
    └── AppConstants.swift
```

## Tecnologie Utilizzate

### Swift & SwiftUI
- **Swift 5.9+**: Linguaggio di programmazione
- **SwiftUI**: Framework UI dichiarativo
- **Combine**: Framework reattivo (@Published)

### Async/Await & Concurrency
- **Async/Await**: Gestione asincrona nativa
- **AsyncThrowingStream**: Per streaming SSE
- **Actors**: Thread-safety per stream concorrenti
- **MainActor**: Garantisce aggiornamenti UI sul main thread

### Networking
- **URLSession**: Client HTTP nativo
- **JSONEncoder/Decoder**: Serializzazione automatica
- **Server-Sent Events (SSE)**: Streaming in tempo reale

### Pattern & Architecture
- **Clean Architecture**: Separazione layer
- **MVVM**: Model-View-ViewModel
- **Repository Pattern**: Astrazione data access
- **Protocol-Oriented Programming**: Astrazione tramite protocolli
- **Dependency Injection**: Via initializer

## Configurazione

### Modalità Mock (Sviluppo)

File: `GPT/Design/AppConstants.swift`

```swift
enum API {
    static let baseURL = "http://127.0.0.1:8000"
    static let useRemoteBackend = false  // Mock mode
}
```

### Modalità Backend Remoto (Produzione)

```swift
enum API {
    static let baseURL = "http://127.0.0.1:8000"  // o IP/URL del backend
    static let useRemoteBackend = true  // Remote mode
}
```

## Requisiti del Backend

Se utilizzate la modalità backend remoto, il server Python deve implementare:

### Endpoints Richiesti

```
GET    /models
GET    /conversations?limit={n}&cursor={cursor}
GET    /conversations/{id}
POST   /conversations
PATCH  /conversations/{id}
DELETE /conversations/{id}
POST   /conversations/{id}/duplicate
GET    /conversations/{id}/messages?limit={n}&cursor={cursor}
POST   /conversations/{id}/messages  [SSE streaming]
```

### Formato SSE

```
data: {"conversationId":"uuid","messageId":"uuid","deltaText":"text","done":false}
```

Vedere [05. Networking](05-networking-backend.md) per dettagli completi del contratto API.

## Build & Run

### Prerequisiti
- macOS 13.0+
- Xcode 14.0+
- Swift 5.9+

### Steps

1. Apri il progetto in Xcode:
   ```bash
   open GPT.xcodeproj
   ```

2. Assicurati che tutti i file siano aggiunti al target (vedi README principale)

3. Build: `Cmd+B`

4. Run: `Cmd+R`

## Testing

### Con Dati Mock
1. Imposta `useRemoteBackend = false`
2. Build & Run
3. L'app funziona con conversazioni e messaggi di esempio

### Con Backend Reale
1. Avvia il backend Python
2. Imposta `useRemoteBackend = true` e `baseURL` corretto
3. Build & Run
4. L'app si connette al backend e funziona con dati reali

## Estensibilità

Questa architettura permette facilmente di:

### Aggiungere Nuove Viste
1. Crea nuova vista SwiftUI in `Views/`
2. Accedi a UIState tramite `@EnvironmentObject`
3. Componi con viste esistenti

### Aggiungere Nuovi Endpoint
1. Aggiungi definizione in `Endpoints.swift`
2. Crea DTO se necessario in `DTOs.swift`
3. Aggiungi metodo al Repository
4. Usa da UIState o Service

### Cambiare Backend
1. Implementa nuovo Repository conformandoti al protocollo `ConversationsRepository`
2. Inietta nel setup iniziale in `GPTApp.swift`
3. Tutto il resto continua a funzionare

### Aggiungere Campi ai Modelli
1. Aggiungi campo allo struct in `Models/`
2. Aggiorna DTO corrispondente
3. Aggiorna mapping `toDomain()`
4. I default values prevengono breaking changes

## Supporto e Contributi

### Segnalazione Bug
Includere:
- Versione macOS
- Steps per riprodurre
- Log di errori
- Screenshot se rilevanti

### Contribuire
1. Segui le Swift API Design Guidelines
2. Mantieni separazione tra layer
3. Aggiungi tests per nuove feature
4. Aggiorna questa documentazione
5. Usa protocol-oriented design

## Prossimi Passi

Dopo aver letto questa documentazione, dovreste essere in grado di:

✅ Comprendere l'architettura generale  
✅ Navigare il codice con sicurezza  
✅ Estendere l'applicazione con nuove feature  
✅ Integrare con un backend  
✅ Debuggare problemi  
✅ Contribuire al progetto  

### Approfondimenti Consigliati

- **Apple SwiftUI Tutorials**: Per pattern SwiftUI avanzati
- **Swift Concurrency**: Per async/await e actors
- **Clean Architecture**: Per principi architetturali
- **Server-Sent Events Spec**: Per comprendere SSE in profondità

## Conclusione

Questa documentazione fornisce una guida completa all'applicazione GPT, coprendo architettura, implementazione e utilizzo. È progettata per essere sia una risorsa di apprendimento che una referenza tecnica.

Per domande specifiche o chiarimenti, consultate il documento pertinente o contattate il team di sviluppo.

**Versione Documentazione**: 1.0  
**Data**: Novembre 2024  
**Autore**: Team GPT  
