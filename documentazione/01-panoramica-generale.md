# Panoramica Generale dell'Applicazione GPT

## Introduzione

L'applicazione GPT è un client nativo macOS sviluppato in SwiftUI che offre un'interfaccia moderna e intuitiva per interagire con modelli di intelligenza artificiale conversazionale. L'applicazione replica l'esperienza utente di ChatGPT, fornendo funzionalità di chat in tempo reale con supporto per streaming delle risposte, gestione di conversazioni multiple e selezione di modelli AI.

## Scopo dell'Applicazione

L'applicazione è progettata per:

1. **Fornire un'interfaccia nativa macOS** per interagire con modelli AI conversazionali
2. **Gestire conversazioni multiple** con organizzazione, ricerca e funzionalità di pinning
3. **Supportare streaming in tempo reale** delle risposte AI tramite tecnologia SSE (Server-Sent Events)
4. **Offrire un'esperienza utente fluida** con animazioni moderne e responsive design
5. **Consentire la selezione di modelli AI** diversi per ogni conversazione
6. **Funzionare sia con backend remoto** che con dati mock locali per sviluppo e testing

## Architettura di Alto Livello

L'applicazione segue un'architettura a livelli pulita (Clean Architecture) con separazione delle responsabilità:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (SwiftUI Views + ViewModels)         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          Business Logic Layer           │
│     (Services + StreamingCenter)        │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          Data Access Layer              │
│        (Repositories + API)             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Network Layer                   │
│      (HTTPClient + SSEClient)           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      Backend / Mock Data Store          │
│   (Python Backend o MockStore)          │
└─────────────────────────────────────────┘
```

## Principali Componenti dell'Applicazione

### 1. Presentation Layer (UI)

La UI è costruita interamente in SwiftUI e consiste in:

- **AppRootView**: La vista radice che gestisce la navigazione principale
- **SidebarView**: Barra laterale con l'elenco delle conversazioni
- **ChatView**: Vista principale della chat con messaggi e composer
- **HomeView**: Vista iniziale mostrata quando nessuna conversazione è selezionata
- **Componenti Condivisi**: Avatar, ErrorBanner, MarkdownMessageView, CodeBlockView, ecc.

### 2. State Management (ViewModels)

- **UIState**: Il cuore della gestione dello stato dell'applicazione, un ObservableObject che:
  - Mantiene la lista delle conversazioni
  - Gestisce la selezione della conversazione attiva
  - Coordina il caricamento dei dati
  - Gestisce gli stati di streaming e errori
  - Sincronizza lo stato con il backend o il mock store

### 3. Business Logic (Services)

- **ChatService**: Gestisce la logica di invio messaggi e streaming delle risposte
- **StreamingCenter**: Actor thread-safe che coordina gli stream SSE multipli per conversazioni diverse

### 4. Data Access (Repositories)

- **ConversationsRepository**: Protocollo che definisce le operazioni sui dati
- **RemoteConversationsRepository**: Implementazione che comunica con il backend Python
- **MockConversationsStore**: Implementazione mock per sviluppo senza backend

### 5. Network Layer

- **HTTPClient**: Client HTTP generico per richieste REST
- **SSEClient**: Client specializzato per lo streaming Server-Sent Events
- **Endpoints**: Definizioni type-safe degli endpoint API
- **DTOs**: Data Transfer Objects per serializzazione/deserializzazione JSON

### 6. Domain Models

- **Conversation**: Modello per le conversazioni (titolo, modello AI, messaggi, ecc.)
- **Message**: Modello per i singoli messaggi (ruolo, testo, stato, timestamp)
- **ChatModel**: Modello per i modelli AI disponibili

## Flusso di Dati Principale

### Scenario 1: Avvio dell'Applicazione

1. **GPTApp.swift** viene eseguito come entry point
2. Verifica la configurazione in **AppConstants** (backend remoto vs mock)
3. Se backend remoto:
   - Crea HTTPClient con baseURL
   - Istanzia RemoteConversationsRepository
   - Crea ChatService con il repository
   - Inizializza UIState con repository e servizio
4. Se mock:
   - Istanzia MockConversationsStore
   - Inizializza UIState con lo store mock
5. Mostra **AppRootView** con lo stato inizializzato

### Scenario 2: Caricamento Conversazioni

1. **UIState** chiama il repository per ottenere le conversazioni
2. **Repository** esegue una richiesta HTTP GET al backend (o restituisce dati mock)
3. Riceve una lista paginata di conversazioni
4. Converte i DTO in modelli di dominio
5. Aggiorna lo stato pubblicato (@Published)
6. **SwiftUI** reagisce automaticamente e aggiorna la UI

### Scenario 3: Invio di un Messaggio e Streaming della Risposta

1. L'utente digita un messaggio nel **ComposerView**
2. **UIState** viene notificato dell'invio
3. Crea un messaggio utente ottimistico e lo aggiunge alla conversazione
4. Chiama **ChatService.streamReply()**
5. **ChatService**:
   - Richiede al repository l'URLRequest per l'invio del messaggio
   - Passa la richiesta a **SSEClient** per iniziare lo streaming
6. **SSEClient** apre una connessione SSE con il backend
7. Per ogni evento SSE ricevuto:
   - Estrae il delta di testo
   - Chiama il callback onDelta
8. **UIState** accumula i delta in un messaggio assistente
9. La UI si aggiorna in tempo reale mostrando il testo che arriva
10. Quando lo streaming è completo (done: true):
    - Il messaggio viene finalizzato
    - Lo stato di streaming termina
    - La UI mostra il messaggio completo

## Modalità di Funzionamento

L'applicazione può operare in due modalità:

### Modalità Mock (Sviluppo)

- Utilizza **MockConversationsStore** con dati di esempio
- Non richiede connessione a backend
- Ideale per sviluppo UI e testing rapido
- Configurabile tramite `AppConstants.API.useRemoteBackend = false`

### Modalità Backend Remoto (Produzione)

- Si connette a un backend Python tramite HTTP/SSE
- Supporta tutte le funzionalità CRUD sulle conversazioni
- Streaming in tempo reale delle risposte AI
- Configurabile tramite `AppConstants.API.useRemoteBackend = true`
- Richiede un backend che implementi il contratto API definito

## Tecnologie e Pattern Utilizzati

### Tecnologie

- **Swift 5.9+**: Linguaggio di programmazione moderno
- **SwiftUI**: Framework UI dichiarativo di Apple
- **Async/Await**: Gestione asincrona nativa di Swift
- **Actors**: Sincronizzazione thread-safe per gestione stream concorrenti
- **Combine**: Framework reattivo (utilizzato tramite @Published)
- **Foundation**: Libreria standard (networking, JSON, date, ecc.)

### Design Patterns

- **Clean Architecture**: Separazione netta tra layer UI, business logic e data
- **Repository Pattern**: Astrazione dell'accesso ai dati
- **MVVM (Model-View-ViewModel)**: Pattern architetturale per la UI
- **Protocol-Oriented Programming**: Uso estensivo di protocolli per astrazione
- **Actor-Based Concurrency**: Gestione thread-safe dello streaming
- **Dependency Injection**: Iniezione delle dipendenze via initializer

### Principi di Design

- **Single Responsibility**: Ogni classe ha una responsabilità chiara
- **Open/Closed Principle**: Estendibile senza modificare codice esistente
- **Dependency Inversion**: Dipendenze verso astrazioni, non implementazioni concrete
- **Type Safety**: Utilizzo estensivo del type system di Swift
- **Immutabilità**: I modelli sono value types immutabili quando possibile

## Caratteristiche Distintive

### 1. Streaming Concorrente Per-Conversazione

L'applicazione supporta stream SSE multipli simultanei, uno per ogni conversazione attiva, gestiti in modo thread-safe tramite l'Actor **StreamingCenter**.

### 2. Paginazione Cursor-Based

Le conversazioni e i messaggi supportano il caricamento lazy con cursori, permettendo di gestire grandi quantità di dati senza caricare tutto in memoria.

### 3. Aggiornamenti Ottimistici

I messaggi utente vengono mostrati immediatamente nella UI prima della conferma del backend, migliorando la percezione di reattività.

### 4. Gestione Completa degli Errori

Tutti i livelli gestiscono gli errori in modo appropriato con:
- Error banners auto-dismissing nella UI
- Logging dettagliato
- Fallback graceful

### 5. Design System Centralizzato

- **AppColors**: Palette colori centralizzata
- **AppTypography**: Stili di testo consistenti
- **AppButtonStyles**: Stili pulsanti riutilizzabili
- **AppConstants**: Configurazione centralizzata

## Configurazione e Personalizzazione

L'applicazione può essere configurata tramite **AppConstants.swift**:

- **API.baseURL**: URL del backend Python
- **API.useRemoteBackend**: Toggle tra mock e backend reale
- **Layout**: Dimensioni sidebar, chat, messaggi, ecc.
- **Spacing**: Sistema di spaziatura consistente
- **Animation**: Configurazione animazioni
- **KeyboardShortcuts**: Scorciatoie da tastiera

## Estensibilità

L'architettura modulare permette di:

1. **Aggiungere nuovi backend**: Implementando il protocollo ConversationsRepository
2. **Estendere i modelli**: I modelli sono value types facilmente estendibili
3. **Aggiungere nuove viste**: SwiftUI permette composizione semplice
4. **Integrare nuove funzionalità**: La separazione dei layer facilita l'aggiunta di features
5. **Supportare nuovi protocolli di streaming**: Astraendo SSEClient

## Sicurezza e Performance

### Sicurezza

- Nessuna autenticazione implementata di default (da aggiungere se necessario)
- Possibilità di aggiungere headers di autenticazione in HTTPClient
- Supporto HTTPS raccomandato per produzione
- Validazione e sanitizzazione degli input

### Performance

- Operazioni asincrone su tutti i livelli
- Actor-based concurrency per thread safety senza lock
- Lazy loading di conversazioni e messaggi
- Caricamento paginato per grandi dataset
- Aggiornamenti ottimistici della UI

## Conclusione

L'applicazione GPT è un esempio di architettura moderna, pulita e scalabile per applicazioni native macOS. Combina le migliori pratiche di sviluppo Swift/SwiftUI con pattern architetturali consolidati, offrendo un'esperienza utente fluida e un codice manutenibile ed estensibile.

Le prossime sezioni della documentazione entreranno nel dettaglio di ogni componente, spiegando l'implementazione tecnica, le scelte di design e fornendo esempi di codice.
