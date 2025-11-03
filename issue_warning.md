# Problema: Mancata Visualizzazione dello Stato di Caricamento dei Messaggi

## Obiettivo Utente

L'obiettivo è migliorare l'esperienza utente nell'invio di messaggi in una conversazione. Quando un utente invia un messaggio, l'interfaccia dovrebbe mostrare immediatamente un feedback visivo (un'animazione di caricamento o uno stato "pending") per il messaggio di risposta dell'assistente. Questo feedback deve rimanere visibile fino a quando non si riceve una risposta definitiva, che può essere:

1.  L'inizio dello streaming del messaggio di risposta.
2.  Un errore di connessione (es. backend non attivo).
3.  Un errore restituito dall'API del backend.

Questo comportamento deve essere consistente e affidabile, anche e soprattutto quando il backend non è raggiungibile, per comunicare chiaramente all'utente che il sistema sta processando la sua richiesta.

## Problema Riscontrato

Nonostante molteplici tentativi di implementazione e debug, la funzionalità non si comporta come previsto. L'utente finale non percepisce alcun cambiamento nell'interfaccia dopo l'invio di un messaggio; non viene visualizzata nessuna animazione di caricamento o stato di attesa.

Questo problema persiste anche dopo aver tentato le seguenti soluzioni:

1.  **Introduzione di un `Message.Status` enum:** È stato creato un sistema di stati esplicito (`pending`, `streaming`, `complete`, `error`) per gestire il ciclo di vita del messaggio.
2.  **Logica di Aggiornamento in `UIState`:** La logica per la gestione della conversazione è stata aggiornata per creare un messaggio segnaposto con stato `.pending` e aggiungerlo alla lista dei messaggi.
3.  **Modifiche alla Vista (`MessageRowView`):** La vista è stata aggiornata per mostrare contenuti diversi in base al `Message.Status`.
4.  **Tentativi di Debug:**
    *   È stato introdotto un ritardo artificiale (`Task.sleep`) per forzare la visualizzazione dello stato di caricamento, senza successo.
    *   È stato forzato il rendering del componente di caricamento per tutti i messaggi dell'assistente, ma non è apparso nulla.
    *   È stato inserito un messaggio di test hardcoded ("Ciao, sono un test!"), ma anche questo non è stato visualizzato.

## Conclusione e Necessità di Refactoring

L'ultimo test, in cui nemmeno un messaggio di test hardcoded e completo viene visualizzato, è l'indizio definitivo che il problema non risiede nella gestione dello stato (`.pending`, `.error`, etc.), ma è più profondo e strutturale.

Il problema principale è quasi certamente nel **flusso di dati (data flow)** e nel modo in cui le viste SwiftUI vengono aggiornate. L'architettura attuale, che passa una copia dell'oggetto `Conversation` da una vista genitore (`AppRootView`) a una figlia (`ChatView`), si è dimostrata inefficace e difficile da debuggare. La catena di aggiornamenti non si propaga correttamente fino alla vista finale, impedendo il rendering di qualsiasi nuovo messaggio (sia esso un segnaposto o un test).

**Azione Richiesta:**
È necessario un **refactoring totale** dell'architettura di `ChatView` e delle viste correlate. La soluzione proposta è la seguente:

1.  **Disaccoppiare `ChatView`:** Modificare `ChatView` in modo che non accetti più l'intero oggetto `Conversation` come parametro. Invece, dovrebbe ricevere solo un `conversationID`.
2.  **Centralizzare l'Accesso ai Dati:** `ChatView` utilizzerà l'ID per recuperare l'oggetto `Conversation` più recente direttamente dalla fonte della verità, ovvero l'oggetto `@EnvironmentObject UIState`.

Questo approccio, più in linea con le best practice di SwiftUI, garantisce che `ChatView` sia sempre sincronizzata con lo stato dell'applicazione e reagisca correttamente ai cambiamenti, risolvendo alla radice il problema di mancato aggiornamento. Continuare a modificare l'implementazione attuale sarebbe inefficiente e non risolverebbe il problema di fondo.

## Post-mortem: perché prima non funzionava, perché ora sì

In origine l'applicazione partiva sempre in modalità *mock* (`AppConstants.API.useRemoteBackend = false`). In quel contesto non viene avviato nessun backend Python, quindi `UIState.submit` si fermava alla ramificazione locale e non creava mai il messaggio segnaposto dell'assistente. La vista `ChatView`, pur essendo già stata disaccoppiata su `conversationID`, non riceveva nessun aggiornamento di stato perché il flusso ottimistico era attivo solo nello scenario remoto.

L'abilitazione del backend remoto ha evidenziato un secondo vincolo: quando la creazione della conversazione remota falliva (server spento o irraggiungibile), la conversazione provvisoria veniva scartata e la UI rimaneva vuota. Questo rendeva impossibile mostrare uno stato "pending" persistente o un errore contestuale.

L'implementazione aggiornata risolve entrambi i punti:

- il flag remoto è attivo di default (`useRemoteBackend = true`) così ogni invio passa dal flusso asincrono pensato per il backend, anche quando il server non risponde;
- `UIState.submitRemote` crea sempre una conversazione provvisoria con un messaggio dell'assistente marcato `.pending`. Se la creazione remota riesce, la conversazione temporanea viene sostituita; se fallisce, il placeholder rimane in UI e viene promosso a `.error`, mentre il banner globale mostra lo stesso messaggio amichevole.

In questo modo l'utente percepisce immediatamente che il sistema sta lavorando (spinner nel bubble e nel composer) e, nel caso di backend non disponibile, riceve un avviso chiaro senza perdere il contesto della nuova conversazione.
