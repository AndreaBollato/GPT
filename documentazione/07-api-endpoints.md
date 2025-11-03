# Documentazione API Endpoints - Applicazione GPT

## Indice

1. [Introduzione](#introduzione)
2. [Configurazione Base](#configurazione-base)
3. [Autenticazione](#autenticazione)
4. [Formato Risposte](#formato-risposte)
5. [Gestione Errori](#gestione-errori)
6. [Endpoints](#endpoints)
   - [Models](#1-models)
   - [Conversations](#2-conversations)
   - [Messages](#3-messages)
7. [Server-Sent Events (SSE)](#server-sent-events-sse)
8. [Esempi Completi](#esempi-completi)

---

## Introduzione

Questo documento descrive tutti gli endpoint API richiesti dal frontend dell'applicazione GPT. Il backend deve implementare esattamente questi endpoint con i formati di input/output specificati.

### Scopo del Documento

- **Per Backend Developers**: Contratto API completo da implementare
- **Per Frontend Developers**: Riferimento per l'integrazione API
- **Per Testing**: Specifiche per creare test di integrazione

---

## Configurazione Base

### Base URL

```
http://127.0.0.1:8000
```

**Nota**: Configurabile in `GPT/Design/AppConstants.swift`

### Headers Comuni

Tutte le richieste includono:

```http
Content-Type: application/json
Accept: application/json
```

Per le richieste SSE (streaming):

```http
Accept: text/event-stream
```

---

## Autenticazione

**Stato Attuale**: Nessuna autenticazione implementata.

**Futuro**: Potrebbe richiedere:
```http
Authorization: Bearer <token>
```

---

## Formato Risposte

### Successo

Tutte le risposte di successo hanno status code `200-299`:

- `200 OK`: Richiesta completata con successo
- `201 Created`: Risorsa creata con successo
- `204 No Content`: Richiesta completata, nessun contenuto da ritornare

### Formato Date

Tutte le date sono in formato ISO 8601:

```json
"2024-11-03T18:13:39.889Z"
```

### Formato UUID

Tutti gli ID sono UUID v4:

```json
"550e8400-e29b-41d4-a716-446655440000"
```

---

## Gestione Errori

### Codici di Errore HTTP

- `400 Bad Request`: Richiesta malformata
- `404 Not Found`: Risorsa non trovata
- `500 Internal Server Error`: Errore del server

### Formato Errore (Opzionale)

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Conversation not found",
    "details": {}
  }
}
```

---

## Endpoints

### 1. Models

#### 1.1 Elenco Modelli AI Disponibili

**Endpoint**: `GET /models`

**Descrizione**: Recupera la lista di tutti i modelli AI disponibili per la chat.

**Request**:
```http
GET /models HTTP/1.1
Host: 127.0.0.1:8000
Accept: application/json
```

**Response**:

Status: `200 OK`

```json
[
  {
    "id": "gpt-5",
    "name": "GPT-5",
    "description": "Modello unificato di OpenAI: prestazioni eccellenti in scrittura, programmazione, matematica e ragionamento multimodale"  
  },
  {
    "id": "claude-sonnet-4.5",
    "name": "Claude Sonnet 4.5",
    "description": "Ultima versione della linea Anthropic Sonnet: alto livello di ragionamento e ottimizzazione per codice e applicazioni aziendali"  
  },
  {
    "id": "claude-opus-4.1",
    "name": "Claude Opus 4.1",
    "description": "Versione top della linea Opus di Anthropic: modello più potente per compiti complessi e contesti estesi"  
  }
]
```

**Campi Response**:

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `id` | string | Identificativo univoco del modello (usato nelle API) |
| `name` | string | Nome visualizzato nell'UI |
| `description` | string | Descrizione del modello (può essere `null`) |

**Frontend Aspettative**:
- Array di oggetti modello
- Campo `description` opzionale (può essere null o stringa vuota)
- Almeno un modello deve essere ritornato

---

### 2. Conversations

#### 2.1 Lista Conversazioni

**Endpoint**: `GET /conversations`

**Descrizione**: Recupera una lista paginata di conversazioni.

**Query Parameters**:

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `limit` | integer | 10 | Numero massimo di conversazioni da ritornare (1-100) |
| `cursor` | string | null | Cursore di paginazione per la pagina successiva |

**Request**:
```http
GET /conversations?limit=10&cursor=eyJpZCI6IjEyMyJ9 HTTP/1.1
Host: 127.0.0.1:8000
Accept: application/json
```

**Response**:

Status: `200 OK`

```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Discussione su architettura software",
      "modelId": "gpt-4",
      "isPinned": true,
      "createdAt": "2024-11-01T10:30:00Z",
      "updatedAt": "2024-11-03T18:13:39Z",
      "lastMessage": {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "role": "assistant",
        "text": "Certamente! L'architettura Clean Architecture...",
        "createdAt": "2024-11-03T18:13:39Z",
        "isPinned": false,
        "isEdited": false
      }
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440002",
      "title": "Nuova conversazione",
      "modelId": "gpt-3.5-turbo",
      "isPinned": false,
      "createdAt": "2024-11-03T15:20:00Z",
      "updatedAt": "2024-11-03T15:20:00Z",
      "lastMessage": null
    }
  ],
  "nextCursor": "eyJpZCI6IjY2MGU4NDAwIn0="
}
```

**Campi Response**:

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `items` | array | Array di conversazioni |
| `items[].id` | UUID | Identificativo univoco della conversazione |
| `items[].title` | string | Titolo della conversazione |
| `items[].modelId` | string | ID del modello AI utilizzato |
| `items[].isPinned` | boolean | Se la conversazione è fissata in alto |
| `items[].createdAt` | ISO 8601 | Data di creazione |
| `items[].updatedAt` | ISO 8601 | Data ultimo aggiornamento |
| `items[].lastMessage` | object \| null | Ultimo messaggio (può essere null) |
| `nextCursor` | string \| null | Cursore per prossima pagina (null se ultima) |

**Frontend Aspettative**:
- Le conversazioni sono ordinate per `updatedAt` (più recenti prima)
- Le conversazioni pinned (`isPinned: true`) dovrebbero apparire per prime
- `lastMessage` può essere `null` se la conversazione è vuota
- `nextCursor` è `null` quando non ci sono altre pagine

---

#### 2.2 Dettaglio Conversazione

**Endpoint**: `GET /conversations/{id}`

**Descrizione**: Recupera i dettagli completi di una conversazione inclusi tutti i messaggi.

**Path Parameters**:

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `id` | UUID | ID della conversazione |

**Request**:
```http
GET /conversations/550e8400-e29b-41d4-a716-446655440000 HTTP/1.1
Host: 127.0.0.1:8000
Accept: application/json
```

**Response**:

Status: `200 OK`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Discussione su architettura software",
  "modelId": "gpt-4",
  "isPinned": true,
  "createdAt": "2024-11-01T10:30:00Z",
  "updatedAt": "2024-11-03T18:13:39Z",
  "messages": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440003",
      "role": "user",
      "text": "Puoi spiegarmi la Clean Architecture?",
      "createdAt": "2024-11-01T10:30:00Z",
      "isPinned": false,
      "isEdited": false
    },
    {
      "id": "880e8400-e29b-41d4-a716-446655440004",
      "role": "assistant",
      "text": "Certamente! La Clean Architecture è un pattern architetturale...",
      "createdAt": "2024-11-01T10:30:15Z",
      "isPinned": false,
      "isEdited": false
    }
  ]
}
```

**Campi Response**:

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `id` | UUID | Identificativo univoco della conversazione |
| `title` | string | Titolo della conversazione |
| `modelId` | string | ID del modello AI utilizzato |
| `isPinned` | boolean | Se la conversazione è fissata in alto |
| `createdAt` | ISO 8601 | Data di creazione |
| `updatedAt` | ISO 8601 | Data ultimo aggiornamento |
| `messages` | array | Array di tutti i messaggi |
| `messages[].id` | UUID | ID del messaggio |
| `messages[].role` | string | Ruolo: "user", "assistant", o "system" |
| `messages[].text` | string | Contenuto del messaggio |
| `messages[].createdAt` | ISO 8601 | Data creazione messaggio |
| `messages[].isPinned` | boolean | Se il messaggio è fissato |
| `messages[].isEdited` | boolean | Se il messaggio è stato modificato |

**Error Response**:

Status: `404 Not Found` se la conversazione non esiste

**Frontend Aspettative**:
- I messaggi sono ordinati cronologicamente (più vecchi prima)
- I messaggi alternano `user` e `assistant`
- Il campo `role` deve essere uno di: "user", "assistant", "system"

---

#### 2.3 Crea Conversazione

**Endpoint**: `POST /conversations`

**Descrizione**: Crea una nuova conversazione, opzionalmente con un primo messaggio.

**Request Body**:

```json
{
  "modelId": "gpt-4",
  "firstMessage": "Ciao, come funziona la programmazione asincrona?"
}
```

**Campi Request**:

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|--------------|-------------|
| `modelId` | string | ✅ | ID del modello AI da utilizzare |
| `firstMessage` | string | ❌ | Primo messaggio dell'utente (opzionale) |

**Request**:
```http
POST /conversations HTTP/1.1
Host: 127.0.0.1:8000
Content-Type: application/json
Accept: application/json

{
  "modelId": "gpt-4",
  "firstMessage": "Ciao, come funziona la programmazione asincrona?"
}
```

**Response**:

Status: `200 OK` o `201 Created`

```json
{
  "conversation": {
    "id": "990e8400-e29b-41d4-a716-446655440005",
    "title": "Nuova Conversazione",
    "modelId": "gpt-4",
    "isPinned": false,
    "createdAt": "2024-11-03T18:15:00Z",
    "updatedAt": "2024-11-03T18:15:00Z",
    "messages": [
      {
        "id": "aa0e8400-e29b-41d4-a716-446655440006",
        "role": "user",
        "text": "Ciao, come funziona la programmazione asincrona?",
        "createdAt": "2024-11-03T18:15:00Z",
        "isPinned": false,
        "isEdited": false
      }
    ]
  }
}
```

**Campi Response**:

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `conversation` | object | Oggetto conversazione creata |
| `conversation.id` | UUID | ID univoco generato dal backend |
| `conversation.title` | string | Titolo di default (es. "Nuova Conversazione") |
| `conversation.modelId` | string | ID del modello specificato |
| `conversation.isPinned` | boolean | Default: `false` |
| `conversation.createdAt` | ISO 8601 | Timestamp di creazione |
| `conversation.updatedAt` | ISO 8601 | Timestamp di aggiornamento |
| `conversation.messages` | array | Array di messaggi (vuoto se no firstMessage) |

**Frontend Aspettative**:
- Se `firstMessage` è presente, deve apparire nell'array `messages`
- Se `firstMessage` è `null` o assente, `messages` è un array vuoto
- Il titolo di default può essere "Nuova Conversazione" o generato dal primo messaggio
- La conversazione NON deve essere automaticamente pinnata

---

#### 2.4 Aggiorna Conversazione

**Endpoint**: `PATCH /conversations/{id}`

**Descrizione**: Aggiorna i metadati di una conversazione (titolo, modello, pin status).

**Path Parameters**:

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `id` | UUID | ID della conversazione |

**Request Body**:

Tutti i campi sono opzionali - invia solo i campi da modificare:

```json
{
  "title": "Architettura Software - Discussion",
  "modelId": "gpt-4",
  "isPinned": true
}
```

**Campi Request**:

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|--------------|-------------|
| `title` | string | ❌ | Nuovo titolo |
| `modelId` | string | ❌ | Nuovo modello AI |
| `isPinned` | boolean | ❌ | Nuovo stato pin |

**Request**:
```http
PATCH /conversations/550e8400-e29b-41d4-a716-446655440000 HTTP/1.1
Host: 127.0.0.1:8000
Content-Type: application/json
Accept: application/json

{
  "isPinned": true
}
```

**Response**:

Status: `200 OK`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Architettura Software - Discussion",
  "modelId": "gpt-4",
  "isPinned": true,
  "createdAt": "2024-11-01T10:30:00Z",
  "updatedAt": "2024-11-03T18:20:00Z",
  "messages": [...]
}
```

**Error Response**:

Status: `404 Not Found` se la conversazione non esiste

**Frontend Aspettative**:
- Solo i campi specificati vengono aggiornati
- `updatedAt` deve essere aggiornato alla data/ora corrente
- La risposta include la conversazione completa con tutti i messaggi

---

#### 2.5 Elimina Conversazione

**Endpoint**: `DELETE /conversations/{id}`

**Descrizione**: Elimina definitivamente una conversazione e tutti i suoi messaggi.

**Path Parameters**:

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `id` | UUID | ID della conversazione da eliminare |

**Request**:
```http
DELETE /conversations/550e8400-e29b-41d4-a716-446655440000 HTTP/1.1
Host: 127.0.0.1:8000
```

**Response**:

Status: `204 No Content`

Nessun body nella response.

**Error Response**:

Status: `404 Not Found` se la conversazione non esiste

**Frontend Aspettative**:
- L'eliminazione è permanente e irreversibile
- Tutti i messaggi associati vengono eliminati
- Status code `204` indica successo anche senza body

---

#### 2.6 Duplica Conversazione

**Endpoint**: `POST /conversations/{id}/duplicate`

**Descrizione**: Crea una copia di una conversazione esistente con tutti i suoi messaggi.

**Path Parameters**:

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `id` | UUID | ID della conversazione da duplicare |

**Request**:
```http
POST /conversations/550e8400-e29b-41d4-a716-446655440000/duplicate HTTP/1.1
Host: 127.0.0.1:8000
Accept: application/json
```

**Response**:

Status: `200 OK` o `201 Created`

```json
{
  "id": "bb0e8400-e29b-41d4-a716-446655440007",
  "title": "Discussione su architettura software (Copia)",
  "modelId": "gpt-4",
  "isPinned": false,
  "createdAt": "2024-11-03T18:25:00Z",
  "updatedAt": "2024-11-03T18:25:00Z",
  "messages": [
    {
      "id": "cc0e8400-e29b-41d4-a716-446655440008",
      "role": "user",
      "text": "Puoi spiegarmi la Clean Architecture?",
      "createdAt": "2024-11-03T18:25:00Z",
      "isPinned": false,
      "isEdited": false
    },
    {
      "id": "dd0e8400-e29b-41d4-a716-446655440009",
      "role": "assistant",
      "text": "Certamente! La Clean Architecture è un pattern architetturale...",
      "createdAt": "2024-11-03T18:25:00Z",
      "isPinned": false,
      "isEdited": false
    }
  ]
}
```

**Campi Response**:

Stessa struttura di una conversazione normale, ma:

| Campo | Descrizione |
|-------|-------------|
| `id` | Nuovo UUID generato |
| `title` | Titolo originale + " (Copia)" o simile |
| `isPinned` | Sempre `false` per le copie |
| `createdAt` | Data/ora corrente |
| `updatedAt` | Data/ora corrente |
| `messages[].id` | Nuovi UUID per ogni messaggio |
| `messages[].createdAt` | Data/ora corrente per tutti i messaggi |

**Error Response**:

Status: `404 Not Found` se la conversazione originale non esiste

**Frontend Aspettative**:
- Tutti i messaggi vengono copiati con nuovo ID
- Il titolo include una indicazione di copia (es. " (Copia)")
- La copia non è mai pinnata
- L'ordine e il contenuto dei messaggi è identico all'originale

---

### 3. Messages

#### 3.1 Lista Messaggi

**Endpoint**: `GET /conversations/{conversationId}/messages`

**Descrizione**: Recupera una lista paginata di messaggi per una conversazione specifica.

**Path Parameters**:

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `conversationId` | UUID | ID della conversazione |

**Query Parameters**:

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `limit` | integer | 30 | Numero massimo di messaggi (1-100) |
| `cursor` | string | null | Cursore di paginazione |

**Request**:
```http
GET /conversations/550e8400-e29b-41d4-a716-446655440000/messages?limit=30 HTTP/1.1
Host: 127.0.0.1:8000
Accept: application/json
```

**Response**:

Status: `200 OK`

```json
{
  "items": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440003",
      "role": "user",
      "text": "Puoi spiegarmi la Clean Architecture?",
      "createdAt": "2024-11-01T10:30:00Z",
      "isPinned": false,
      "isEdited": false
    },
    {
      "id": "880e8400-e29b-41d4-a716-446655440004",
      "role": "assistant",
      "text": "Certamente! La Clean Architecture è un pattern architetturale...",
      "createdAt": "2024-11-01T10:30:15Z",
      "isPinned": false,
      "isEdited": false
    }
  ],
  "nextCursor": null
}
```

**Campi Response**:

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `items` | array | Array di messaggi |
| `items[].id` | UUID | ID del messaggio |
| `items[].role` | string | "user", "assistant", o "system" |
| `items[].text` | string | Contenuto del messaggio |
| `items[].createdAt` | ISO 8601 | Data creazione |
| `items[].isPinned` | boolean | Se il messaggio è fissato |
| `items[].isEdited` | boolean | Se il messaggio è modificato |
| `nextCursor` | string \| null | Cursore prossima pagina |

**Error Response**:

Status: `404 Not Found` se la conversazione non esiste

**Frontend Aspettative**:
- I messaggi sono ordinati cronologicamente (più vecchi prima)
- Usato per lazy loading quando ci sono molti messaggi
- Se `cursor` non è specificato, ritorna i messaggi più recenti

---

#### 3.2 Invia Messaggio (con Streaming SSE)

**Endpoint**: `POST /conversations/{conversationId}/messages`

**Descrizione**: Invia un nuovo messaggio dell'utente e riceve la risposta dell'assistente tramite Server-Sent Events (SSE) streaming.

**Path Parameters**:

| Parametro | Tipo | Descrizione |
|-----------|------|-------------|
| `conversationId` | UUID | ID della conversazione |

**Request Body**:

```json
{
  "role": "user",
  "text": "Come funziona async/await in Swift?"
}
```

**Campi Request**:

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|--------------|-------------|
| `role` | string | ✅ | Ruolo del messaggio (tipicamente "user") |
| `text` | string | ✅ | Testo del messaggio |

**Request**:
```http
POST /conversations/550e8400-e29b-41d4-a716-446655440000/messages HTTP/1.1
Host: 127.0.0.1:8000
Accept: text/event-stream
Content-Type: application/json

{
  "role": "user",
  "text": "Come funziona async/await in Swift?"
}
```

**Response**:

Status: `200 OK`

Content-Type: `text/event-stream`

La risposta è uno stream di eventi SSE. Vedere sezione [Server-Sent Events](#server-sent-events-sse) per dettagli completi.

**Formato Eventi SSE**:

```
data: {"conversationId":"550e8400-e29b-41d4-a716-446655440000","messageId":"ee0e8400-e29b-41d4-a716-446655440010","deltaText":"Async","done":false}

data: {"conversationId":"550e8400-e29b-41d4-a716-446655440000","messageId":"ee0e8400-e29b-41d4-a716-446655440010","deltaText":"/await","done":false}

data: {"conversationId":"550e8400-e29b-41d4-a716-446655440000","messageId":"ee0e8400-e29b-41d4-a716-446655440010","deltaText":" in Swift permette...","done":false}

data: {"conversationId":"550e8400-e29b-41d4-a716-446655440000","messageId":"ee0e8400-e29b-41d4-a716-446655440010","fullText":"Async/await in Swift permette di scrivere codice asincrono in modo più leggibile...","done":true}
```

**Error Response**:

Status: `404 Not Found` se la conversazione non esiste

**Frontend Aspettative**:
- Il messaggio dell'utente viene salvato immediatamente
- La risposta dell'assistente arriva tramite streaming SSE
- Il frontend deve gestire eventi SSE incrementali
- L'ultimo evento ha `"done": true`

---

## Server-Sent Events (SSE)

### Descrizione

Server-Sent Events (SSE) è utilizzato per lo streaming in tempo reale delle risposte dell'assistente AI. Permette al backend di inviare incrementalmente il testo mentre viene generato, offrendo un'esperienza utente migliore.

### Formato Eventi

Ogni evento SSE ha questo formato:

```
data: <JSON_OBJECT>

```

Nota: Ogni messaggio SSE termina con doppio newline (`\n\n`).

### Struttura JSON Evento

```json
{
  "conversationId": "550e8400-e29b-41d4-a716-446655440000",
  "messageId": "ee0e8400-e29b-41d4-a716-446655440010",
  "deltaText": "porzione di testo",
  "fullText": "testo completo fino ad ora",
  "done": false
}
```

### Campi Evento SSE

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|--------------|-------------|
| `conversationId` | UUID string | ❌ | ID della conversazione (opzionale ma consigliato) |
| `messageId` | UUID string | ❌ | ID del messaggio assistant (opzionale ma consigliato) |
| `deltaText` | string | ❌ | Incremento di testo da aggiungere |
| `fullText` | string | ❌ | Testo completo del messaggio fino ad ora |
| `done` | boolean | ✅ | `true` quando lo streaming è completato |

### Modalità di Streaming

#### Modalità Mista (Raccomandata)

Invia deltaText durante lo streaming e fullText alla fine:

```
data: {"deltaText":"Async","done":false}

data: {"deltaText":"/await è fantastico!","done":false}

data: {"messageId":"ee0e8400-e29b-41d4-a716-446655440010","fullText":"Async/await è fantastico!","done":true}
```

### Evento Finale

L'ultimo evento DEVE avere `"done": true`:

```
data: {"conversationId":"550e8400-e29b-41d4-a716-446655440000","messageId":"ee0e8400-e29b-41d4-a716-446655440010","fullText":"Testo completo della risposta","done":true}
```

### Best Practices SSE

1. **Timeout**: Mantenere la connessione aperta per max 5 minuti o fino alla fine dello streaming
2. **Heartbeat**: Inviare eventi periodici per mantenere la connessione viva
3. **Error Handling**: Chiudere correttamente lo stream in caso di errore
4. **IDs**: Includere `messageId` per permettere il tracking
5. **Frequenza**: Inviare eventi ogni 50-200ms per bilanciare reattività e overhead

### Gestione Errori SSE

Se si verifica un errore durante lo streaming:

```
data: {"error":"Internal server error","done":true}
```

O chiudere semplicemente la connessione (il frontend gestirà come errore di rete).

---

## Esempi Completi

### Esempio 1: Creazione Conversazione e Invio Messaggio

#### Step 1: Crea conversazione

```http
POST /conversations HTTP/1.1
Host: 127.0.0.1:8000
Content-Type: application/json

{
  "modelId": "gpt-4",
  "firstMessage": "Spiegami le Promises in JavaScript"
}
```

**Response**:
```json
{
  "conversation": {
    "id": "ff0e8400-e29b-41d4-a716-446655440011",
    "title": "Nuova Conversazione",
    "modelId": "gpt-4",
    "isPinned": false,
    "createdAt": "2024-11-03T18:30:00Z",
    "updatedAt": "2024-11-03T18:30:00Z",
    "messages": [
      {
        "id": "000f8400-e29b-41d4-a716-446655440012",
        "role": "user",
        "text": "Spiegami le Promises in JavaScript",
        "createdAt": "2024-11-03T18:30:00Z",
        "isPinned": false,
        "isEdited": false
      }
    ]
  }
}
```

#### Step 2: Invia messaggio per ottenere risposta (SSE)

```http
POST /conversations/ff0e8400-e29b-41d4-a716-446655440011/messages HTTP/1.1
Host: 127.0.0.1:8000
Accept: text/event-stream
Content-Type: application/json

{
  "role": "user",
  "text": "Puoi fare un esempio pratico?"
}
```

**Response Stream**:
```
data: {"deltaText":"Certamente!","done":false}

data: {"deltaText":" Ecco un esempio:","done":false}

data: {"deltaText":"\n\n```javascript\nconst promise = new Promise(...)\n```","done":false}

data: {"messageId":"110f8400-e29b-41d4-a716-446655440013","fullText":"Certamente! Ecco un esempio:\n\n```javascript\nconst promise = new Promise((resolve, reject) => {\n  setTimeout(() => resolve('Fatto!'), 1000);\n});\n```","done":true}
```

---

### Esempio 2: Gestione Conversazioni Pinned

#### Step 1: Lista conversazioni

```http
GET /conversations?limit=10 HTTP/1.1
Host: 127.0.0.1:8000
```

**Response**:
```json
{
  "items": [
    {
      "id": "220f8400-e29b-41d4-a716-446655440014",
      "title": "Importante: Architettura",
      "modelId": "gpt-4",
      "isPinned": true,
      "createdAt": "2024-11-01T10:00:00Z",
      "updatedAt": "2024-11-03T17:00:00Z",
      "lastMessage": {...}
    },
    {
      "id": "330f8400-e29b-41d4-a716-446655440015",
      "title": "Conversazione recente",
      "modelId": "gpt-3.5-turbo",
      "isPinned": false,
      "createdAt": "2024-11-03T18:00:00Z",
      "updatedAt": "2024-11-03T18:00:00Z",
      "lastMessage": {...}
    }
  ],
  "nextCursor": null
}
```

#### Step 2: Pin una conversazione

```http
PATCH /conversations/330f8400-e29b-41d4-a716-446655440015 HTTP/1.1
Host: 127.0.0.1:8000
Content-Type: application/json

{
  "isPinned": true
}
```

**Response**:
```json
{
  "id": "330f8400-e29b-41d4-a716-446655440015",
  "title": "Conversazione recente",
  "modelId": "gpt-3.5-turbo",
  "isPinned": true,
  "createdAt": "2024-11-03T18:00:00Z",
  "updatedAt": "2024-11-03T18:35:00Z",
  "messages": [...]
}
```

---

### Esempio 3: Paginazione Messaggi

#### Request - Prima pagina

```http
GET /conversations/550e8400-e29b-41d4-a716-446655440000/messages?limit=2 HTTP/1.1
Host: 127.0.0.1:8000
```

**Response**:
```json
{
  "items": [
    {
      "id": "440f8400-e29b-41d4-a716-446655440016",
      "role": "user",
      "text": "Messaggio 1",
      "createdAt": "2024-11-03T10:00:00Z",
      "isPinned": false,
      "isEdited": false
    },
    {
      "id": "550f8400-e29b-41d4-a716-446655440017",
      "role": "assistant",
      "text": "Risposta 1",
      "createdAt": "2024-11-03T10:00:05Z",
      "isPinned": false,
      "isEdited": false
    }
  ],
  "nextCursor": "eyJpZCI6IjU1MGY4NDAwIn0="
}
```

#### Request - Pagina successiva

```http
GET /conversations/550e8400-e29b-41d4-a716-446655440000/messages?limit=2&cursor=eyJpZCI6IjU1MGY4NDAwIn0= HTTP/1.1
Host: 127.0.0.1:8000
```

**Response**:
```json
{
  "items": [
    {
      "id": "660f8400-e29b-41d4-a716-446655440018",
      "role": "user",
      "text": "Messaggio 2",
      "createdAt": "2024-11-03T10:05:00Z",
      "isPinned": false,
      "isEdited": false
    },
    {
      "id": "770f8400-e29b-41d4-a716-446655440019",
      "role": "assistant",
      "text": "Risposta 2",
      "createdAt": "2024-11-03T10:05:05Z",
      "isPinned": false,
      "isEdited": false
    }
  ],
  "nextCursor": null
}
```

---

## Riepilogo Endpoints

### Tabella Rapida

| Metodo | Endpoint | Descrizione | SSE |
|--------|----------|-------------|-----|
| GET | `/models` | Lista modelli AI | ❌ |
| GET | `/conversations` | Lista conversazioni (paginata) | ❌ |
| GET | `/conversations/{id}` | Dettaglio conversazione | ❌ |
| POST | `/conversations` | Crea conversazione | ❌ |
| PATCH | `/conversations/{id}` | Aggiorna conversazione | ❌ |
| DELETE | `/conversations/{id}` | Elimina conversazione | ❌ |
| POST | `/conversations/{id}/duplicate` | Duplica conversazione | ❌ |
| GET | `/conversations/{id}/messages` | Lista messaggi (paginata) | ❌ |
| POST | `/conversations/{id}/messages` | Invia messaggio + streaming | ✅ |

### Entità Principali

#### Model
```json
{
  "id": "string",
  "name": "string",
  "description": "string | null"
}
```

#### Conversation (Meta)
```json
{
  "id": "UUID",
  "title": "string",
  "modelId": "string",
  "isPinned": "boolean",
  "createdAt": "ISO 8601",
  "updatedAt": "ISO 8601",
  "lastMessage": "Message | null"
}
```

#### Conversation (Full)
```json
{
  "id": "UUID",
  "title": "string",
  "modelId": "string",
  "isPinned": "boolean",
  "createdAt": "ISO 8601",
  "updatedAt": "ISO 8601",
  "messages": "Message[]"
}
```

#### Message
```json
{
  "id": "UUID",
  "role": "user | assistant | system",
  "text": "string",
  "createdAt": "ISO 8601",
  "isPinned": "boolean",
  "isEdited": "boolean"
}
```

---

## Note Implementative per il Backend

### Requisiti Obbligatori

1. **UUID Generation**: Il backend deve generare UUID v4 validi
2. **Timestamp ISO 8601**: Tutte le date devono essere ISO 8601 con timezone UTC
3. **SSE Streaming**: Implementare correttamente il protocollo SSE per `/messages` POST
4. **Paginazione**: Implementare cursore di paginazione (può essere base64 dell'ultimo ID)
5. **Validazione**: Validare tutti gli input (UUID validi, limiti, ecc.)

### Best Practices

1. **Idempotenza**: POST duplicate dovrebbe essere idempotente se possibile
2. **Soft Delete**: Considerare soft delete per recupero dati
3. **Rate Limiting**: Implementare rate limiting per protezione
4. **Logging**: Loggare tutte le richieste per debugging
5. **CORS**: Configurare CORS se frontend e backend sono su domini diversi

### Performance

1. **Index Database**: Creare indici su `conversationId`, `createdAt`, `updatedAt`
2. **Lazy Loading**: Supportare paginazione efficiente per grandi dataset
3. **Caching**: Considerare cache per lista modelli (raramente cambia)
4. **Connection Pooling**: Usare connection pooling per il database

### Sicurezza

1. **Input Validation**: Validare rigorosamente tutti gli input
2. **SQL Injection**: Usare prepared statements
3. **XSS**: Sanitize text input se necessario
4. **Rate Limiting**: Protezione contro abusi
5. **Authentication**: Preparare per futura aggiunta autenticazione

---

## Testing API

### Tools Consigliati

- **cURL**: Per test rapidi da linea di comando
- **Postman**: Per test interattivi e collezioni
- **pytest** (Python): Per test automatici backend
- **XCTest** (Swift): Per test integrazione frontend

### Esempio Test cURL

```bash
# Lista modelli
curl http://127.0.0.1:8000/models

# Crea conversazione
curl -X POST http://127.0.0.1:8000/conversations \
  -H "Content-Type: application/json" \
  -d '{"modelId":"gpt-4","firstMessage":"Ciao!"}'

# Lista conversazioni
curl http://127.0.0.1:8000/conversations?limit=10

# SSE Streaming
curl -N -H "Accept: text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"role":"user","text":"Ciao"}' \
  http://127.0.0.1:8000/conversations/{id}/messages
```

---

## Changelog API

### Versione 1.0 (Attuale)

- Endpoint base per modelli, conversazioni e messaggi
- SSE streaming per risposte AI
- Paginazione con cursori
- CRUD completo per conversazioni
- Operazioni: pin, duplicate, delete
