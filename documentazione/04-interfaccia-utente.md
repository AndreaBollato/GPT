# Interfaccia Utente e Componenti SwiftUI

## Introduzione

Questa sezione descrive in dettaglio l'interfaccia utente dell'applicazione, costruita interamente con SwiftUI. Analizzeremo la struttura delle viste, i pattern di composizione, la gestione dello stato e le interazioni utente.

## Filosofia del Design UI

### Principi di Design

1. **Minimalista**: Focus sul contenuto, interfaccia pulita
2. **Nativa macOS**: Segue le Human Interface Guidelines di Apple
3. **Responsive**: Si adatta a diverse dimensioni di finestra
4. **Accessibile**: Supporto per VoiceOver e altre tecnologie assistive
5. **Performante**: Rendering efficiente anche con molti messaggi

### Palette Colori

Definita in `Design/AppColors.swift`:

```swift
struct AppColors {
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    static let text = Color.primary
    static let secondaryText = Color.secondary
    static let accent = Color.accentColor
    // ... altri colori
}
```

### Tipografia

Definita in `Design/AppTypography.swift`:

```swift
struct AppTypography {
    static let title = Font.system(.title, design: .default)
    static let headline = Font.system(.headline, design: .default)
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.caption, design: .default)
    // ... altri stili
}
```

## Struttura della UI

### Gerarchia delle Viste

```
AppRootView (Root)
├── NavigationSplitView
│   ├── Sidebar
│   │   └── SidebarView
│   │       ├── Search Bar
│   │       ├── New Chat Button
│   │       ├── Pinned Section
│   │       │   └── ConversationRowView (×N)
│   │       └── Recent Section
│   │           └── ConversationRowView (×N)
│   │
│   └── Detail
│       ├── HomeView (quando nessuna conversazione è selezionata)
│       │   ├── Welcome Message
│       │   ├── Model Selector
│       │   └── ComposerView
│       │
│       └── ChatView (quando una conversazione è selezionata)
│           ├── TopBarView
│           │   ├── Title
│           │   ├── Model Badge
│           │   └── Actions Menu
│           ├── Message List
│           │   └── MessageRowView (×N)
│           │       ├── AvatarView
│           │       └── MarkdownMessageView
│           │           └── CodeBlockView (se necessario)
│           └── ComposerView
│
└── ErrorBanner (overlay quando presente errore)
```

## AppRootView - Vista Radice

### Responsabilità

- Gestire il NavigationSplitView
- Mostrare ErrorBanner globale
- Iniettare UIState come EnvironmentObject
- Gestire la visibilità delle colonne

### Struttura

```swift
struct AppRootView: View {
    @StateObject private var uiState: UIState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @FocusState private var searchFocused: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView(searchFocus: $searchFocused)
            } detail: {
                Group {
                    if let selected = uiState.selectedConversationID {
                        ChatView(conversationID: selected, 
                                onSearchTapped: { searchFocused = true })
                    } else {
                        HomeView(onSearchTapped: { searchFocused = true })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
            }
            .environmentObject(uiState)
            .navigationSplitViewStyle(.balanced)
            .background(AppColors.background)
            
            // Error banner overlay
            if let errorMessage = uiState.errorMessage {
                ErrorBanner(message: errorMessage, onDismiss: {
                    uiState.errorMessage = nil
                })
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: uiState.errorMessage)
            }
        }
    }
}
```

### Caratteristiche

- **NavigationSplitView**: Layout a due colonne (sidebar + detail)
- **Conditional Rendering**: Mostra HomeView o ChatView in base alla selezione
- **EnvironmentObject**: UIState accessibile a tutte le viste figlie
- **FocusState**: Gestione focus per la ricerca
- **ZStack**: Overlay per ErrorBanner

## SidebarView - Barra Laterale

### Responsabilità

- Mostrare lista conversazioni
- Permettere ricerca
- Gestire creazione nuova conversazione
- Separare conversazioni pinnate da recenti
- Scroll infinito (paginazione)

### Struttura

```swift
struct SidebarView: View {
    @EnvironmentObject private var uiState: UIState
    @FocusState.Binding var searchFocus: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con ricerca e nuovo chat
            headerView
            
            Divider()
            
            // Lista conversazioni
            ScrollView {
                LazyVStack(spacing: AppSpacing.sm) {
                    // Sezione Pinned
                    if !uiState.pinnedConversations.isEmpty {
                        pinnedSection
                    }
                    
                    // Sezione Recent
                    if !uiState.recentConversations.isEmpty {
                        recentSection
                    }
                    
                    // Load more
                    if uiState.hasMoreConversations {
                        loadMoreButton
                    }
                }
                .padding(AppSpacing.md)
            }
        }
        .frame(
            minWidth: AppConstants.Layout.sidebarMinWidth,
            idealWidth: AppConstants.Layout.sidebarIdealWidth,
            maxWidth: AppConstants.Layout.sidebarMaxWidth
        )
        .background(AppColors.secondaryBackground)
    }
    
    private var headerView: some View {
        VStack(spacing: AppSpacing.sm) {
            // Barra di ricerca
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search conversations...", text: $uiState.searchQuery)
                    .textFieldStyle(.plain)
                    .focused($searchFocus)
                
                if !uiState.searchQuery.isEmpty {
                    Button(action: { uiState.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.sm)
            .background(AppColors.background)
            .cornerRadius(AppConstants.Layout.cardCornerRadius)
            
            // Pulsante nuova chat
            Button(action: { uiState.createNewConversation() }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("New Chat")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppButtonStyles.Primary())
            .keyboardShortcut(AppConstants.KeyboardShortcuts.newConversation)
        }
        .padding(AppSpacing.md)
    }
}
```

### Caratteristiche

- **LazyVStack**: Caricamento lazy per performance
- **Sezioni Separate**: Pinned in alto, Recent sotto
- **Search Bar**: Filtraggio in tempo reale
- **Keyboard Shortcuts**: Cmd+N per nuova chat, Cmd+F per ricerca
- **Frame Constraints**: Larghezza min/ideal/max per responsive design

## ConversationRowView - Riga Conversazione

### Responsabilità

- Visualizzare singola conversazione nella lista
- Mostrare titolo, snippet ultimo messaggio, timestamp
- Gestire selezione
- Menu contestuale (rinomina, pin, duplica, elimina)

### Struttura

```swift
struct ConversationRowView: View {
    let conversation: Conversation
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject private var uiState: UIState
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack {
                        Text(conversation.title)
                            .font(AppTypography.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if conversation.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(conversation.lastMessageSnippet)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(conversation.lastActivityDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(isSelected ? AppColors.accent.opacity(0.1) : Color.clear)
            .cornerRadius(AppConstants.Layout.cardCornerRadius)
        }
        .buttonStyle(.plain)
        .contextMenu {
            contextMenuItems
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Rename") {
            // Implementazione rename
        }
        
        Button(conversation.isPinned ? "Unpin" : "Pin") {
            uiState.togglePin(conversationId: conversation.id)
        }
        
        Button("Duplicate") {
            uiState.duplicateConversation(id: conversation.id)
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            uiState.deleteConversation(id: conversation.id)
        }
    }
}
```

### Caratteristiche

- **Highlight selezione**: Background colorato quando selezionata
- **Context Menu**: Click destro per azioni
- **Relative Time**: "2 minutes ago", "1 hour ago"
- **Pin Indicator**: Icona pin per conversazioni fissate

## HomeView - Vista Iniziale

### Responsabilità

- Mostrare schermata di benvenuto
- Permettere selezione modello
- Fornire composer per iniziare nuova conversazione
- Mostrare suggerimenti o esempi (opzionale)

### Struttura

```swift
struct HomeView: View {
    @EnvironmentObject private var uiState: UIState
    @State private var draft: String = ""
    let onSearchTapped: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            // Icona e titolo
            VStack(spacing: AppSpacing.xl) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("Start a New Conversation")
                    .font(AppTypography.title)
                    .foregroundColor(.primary)
                
                Text("Select a model and type your message below")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Model Selector
            ModelPickerView(selectedModelId: $uiState.activeModelId)
                .padding(.bottom, AppSpacing.md)
            
            // Composer
            ComposerView(
                draft: $uiState.homeDraft,
                isStreaming: false,
                onSend: { text in
                    uiState.createNewConversation(withMessage: text)
                },
                onStop: {}
            )
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: AppConstants.Layout.detailMaxWidth)
        .frame(maxWidth: .infinity)
    }
}
```

### Caratteristiche

- **Centered Layout**: Contenuto centrato verticalmente e orizzontalmente
- **Max Width**: Limita larghezza per leggibilità
- **Model Selection**: Permette scelta modello prima di iniziare
- **Spacer**: Distribuzione verticale dello spazio

## ChatView - Vista Conversazione

### Responsabilità

- Mostrare messaggi della conversazione
- Gestire scroll automatico
- Mostrare TopBar con azioni
- Fornire composer per nuovi messaggi
- Gestire lazy loading messaggi più vecchi

### Struttura

```swift
struct ChatView: View {
    let conversationID: UUID
    let onSearchTapped: () -> Void
    
    @EnvironmentObject private var uiState: UIState
    @State private var scrollProxy: ScrollViewProxy?
    
    var conversation: Conversation? {
        uiState.conversations.first { $0.id == conversationID }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            if let conv = conversation {
                TopBarView(conversation: conv, onSearchTapped: onSearchTapped)
                Divider()
            }
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        // Load more button
                        if uiState.hasMoreMessages(for: conversationID) {
                            loadMoreButton
                        }
                        
                        // Messages
                        ForEach(conversation?.messages ?? []) { message in
                            MessageRowView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(AppSpacing.xxl)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: conversation?.messages.count) { _ in
                    scrollToBottom()
                }
            }
            
            Divider()
            
            // Composer
            ComposerView(
                draft: uiState.draftBinding(for: conversationID),
                isStreaming: uiState.isStreaming(conversationID: conversationID),
                onSend: { text in
                    uiState.sendMessage(text, in: conversationID)
                },
                onStop: {
                    uiState.stopStreaming(for: conversationID)
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func scrollToBottom() {
        guard let lastMessage = conversation?.messages.last else { return }
        withAnimation {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}
```

### Caratteristiche

- **ScrollViewReader**: Per scroll programmatico
- **Auto-scroll**: Scroll automatico a nuovo messaggio
- **LazyVStack**: Performance con molti messaggi
- **Load More**: Caricamento messaggi più vecchi
- **Binding Dinamico**: Draft specifico per conversazione

## TopBarView - Barra Superiore

### Responsabilità

- Mostrare titolo conversazione
- Mostrare badge modello corrente
- Fornire menu azioni (pin, rename, delete, ecc.)

### Struttura

```swift
struct TopBarView: View {
    let conversation: Conversation
    let onSearchTapped: () -> Void
    @EnvironmentObject private var uiState: UIState
    
    var body: some View {
        HStack {
            // Titolo
            Text(conversation.title)
                .font(AppTypography.headline)
                .lineLimit(1)
            
            // Badge modello
            if let model = uiState.availableModels.first(where: { $0.id == conversation.modelId }) {
                Text(model.displayName)
                    .font(.caption)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColors.accent.opacity(0.1))
                    .foregroundColor(AppColors.accent)
                    .cornerRadius(AppConstants.Layout.cardCornerRadius / 2)
            }
            
            Spacer()
            
            // Actions menu
            Menu {
                menuItems
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
    }
    
    @ViewBuilder
    private var menuItems: some View {
        Button("Search") {
            onSearchTapped()
        }
        
        Button("Change Model") {
            // Implementazione
        }
        
        Divider()
        
        Button(conversation.isPinned ? "Unpin" : "Pin") {
            uiState.togglePin(conversationId: conversation.id)
        }
        
        Button("Duplicate") {
            uiState.duplicateConversation(id: conversation.id)
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            uiState.deleteConversation(id: conversation.id)
        }
    }
}
```

## MessageRowView - Riga Messaggio

### Responsabilità

- Visualizzare un singolo messaggio
- Differenziare stile per user/assistant
- Mostrare avatar
- Renderizzare markdown
- Mostrare indicatore streaming

### Struttura

```swift
struct MessageRowView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Avatar
            AvatarView(role: message.role)
            
            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Nome
                Text(message.role.displayName)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                
                // Messaggio
                MarkdownMessageView(text: message.text)
                
                // Status indicator
                if case .streaming = message.status {
                    HStack(spacing: AppSpacing.xxs) {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Thinking...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if case let .error(errorText) = message.status {
                    Text("Error: \(errorText)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: AppConstants.Layout.messageMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: message.role.isUser ? .trailing : .leading)
    }
}
```

### Caratteristiche

- **Layout Asimmetrico**: Messaggi user a destra, assistant a sinistra
- **Max Width**: Limita larghezza per leggibilità
- **Status Indicators**: Spinner per streaming, errore in rosso
- **Avatar**: Icona diversa per user/assistant

## MarkdownMessageView - Rendering Markdown

### Responsabilità

- Renderizzare testo markdown
- Evidenziare blocchi di codice
- Supportare formattazione (bold, italic, link)

### Struttura

```swift
struct MarkdownMessageView: View {
    let text: String
    
    var body: some View {
        // Semplice implementazione
        // In produzione userebbe libreria markdown o Text con AttributedString
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(parseBlocks(text), id: \.self) { block in
                if block.isCode {
                    CodeBlockView(code: block.content, language: block.language)
                } else {
                    Text(block.content)
                        .textSelection(.enabled)
                }
            }
        }
    }
    
    private func parseBlocks(_ text: String) -> [TextBlock] {
        // Parsing semplificato di markdown
        // Rileva blocchi ```code``` e testo normale
        // Implementazione completa ometsa per brevità
        []
    }
}
```

## CodeBlockView - Blocco Codice

### Responsabilità

- Visualizzare codice con syntax highlighting
- Mostrare badge linguaggio
- Fornire pulsante copia

### Struttura

```swift
struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                if let lang = language {
                    Text(lang.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: copyCode) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.secondaryBackground.opacity(0.5))
            
            // Code
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(AppSpacing.md)
            }
            .background(AppColors.secondaryBackground)
        }
        .cornerRadius(AppConstants.Layout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        copied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}
```

## ComposerView - Input Messaggi

### Responsabilità

- Permettere input testo multiline
- Auto-resize basato su contenuto
- Gestire invio (Cmd+Enter)
- Mostrare pulsante stop durante streaming

### Struttura

```swift
struct ComposerView: View {
    @Binding var draft: String
    let isStreaming: Bool
    let onSend: (String) -> Void
    let onStop: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.md) {
            // Text editor
            TextEditor(text: $draft)
                .font(AppTypography.body)
                .frame(
                    minHeight: AppConstants.Layout.composerMinHeight,
                    maxHeight: AppConstants.Layout.composerMaxHeight
                )
                .focused($isFocused)
                .onSubmit {
                    if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        send()
                    }
                }
            
            // Send/Stop button
            if isStreaming {
                Button(action: onStop) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .keyboardShortcut(.escape, modifiers: [])
            } else {
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(AppConstants.KeyboardShortcuts.sendMessage)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .onAppear {
            isFocused = true
        }
    }
    
    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        onSend(text)
        draft = ""
    }
}
```

### Caratteristiche

- **Auto-resize**: Si espande fino a maxHeight
- **Keyboard Shortcuts**: Cmd+Enter per inviare, Esc per stop
- **Disabled State**: Pulsante invia disabilitato se vuoto
- **Auto-focus**: Focus automatico all'apparizione
- **Dynamic Button**: Cambia tra Send e Stop

## ErrorBanner - Banner Errori

### Responsabilità

- Mostrare errori in modo non invasivo
- Auto-dismiss dopo alcuni secondi
- Permettere dismiss manuale

### Struttura

```swift
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(AppTypography.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(Color.red)
        .cornerRadius(AppConstants.Layout.cardCornerRadius)
        .shadow(radius: AppSpacing.sm)
        .onAppear {
            // Auto-dismiss dopo 5 secondi
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onDismiss()
            }
        }
    }
}
```

## Gestione dello Stato nella UI

### @EnvironmentObject

UIState è iniettato come EnvironmentObject e accessibile a tutte le viste:

```swift
struct SomeView: View {
    @EnvironmentObject private var uiState: UIState
    
    var body: some View {
        Text("Conversations: \(uiState.conversations.count)")
    }
}
```

### @Published e Reattività

Le properties @Published in UIState triggherano automaticamente re-rendering:

```swift
// In UIState
@Published var conversations: [Conversation] = []

// Quando cambia:
conversations.append(newConversation)  // UI si aggiorna automaticamente
```

### Binding

Binding bidirezionali per input:

```swift
TextField("Search", text: $uiState.searchQuery)
// Modifica searchQuery quando l'utente digita
// Aggiorna TextField quando searchQuery cambia
```

## Animazioni e Transizioni

### Animazioni Implicite

```swift
.animation(.spring(), value: uiState.errorMessage)
```

### Transizioni

```swift
.transition(.move(edge: .top).combined(with: .opacity))
```

### Animazioni Custom

```swift
withAnimation(AppConstants.Animation.smoothSpring) {
    scrollProxy?.scrollTo(messageId)
}
```

## Best Practices UI

1. **Lazy Loading**: Usa LazyVStack/LazyHStack per liste lunghe
2. **Frame Constraints**: Specifica min/ideal/max width per layout responsive
3. **Spacing Consistente**: Usa AppSpacing per spaziatura uniforme
4. **Color Semantics**: Usa AppColors, non colori hard-coded
5. **Accessibility**: Fornisci label accessibili
6. **Performance**: Evita computazioni pesanti in body
7. **Composizione**: Scomponi viste complesse in componenti riutilizzabili

## Conclusione

L'interfaccia utente dell'applicazione GPT è costruita con SwiftUI seguendo le migliori pratiche di Apple. La struttura modulare, la gestione reattiva dello stato e l'attenzione ai dettagli creano un'esperienza utente fluida e nativa su macOS.
