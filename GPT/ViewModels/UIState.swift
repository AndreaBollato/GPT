import Foundation
import Combine

protocol ConversationsUIStore: AnyObject {
    var availableModels: [ChatModel] { get }

    func fetchConversations() -> [Conversation]
    func createConversation(initialMessage: Message?, modelId: String) -> Conversation
    func updateConversation(id: Conversation.ID, mutate: (inout Conversation) -> Void) -> Conversation?
    func deleteConversation(id: Conversation.ID)
    func duplicateConversation(id: Conversation.ID) -> Conversation?
}

enum ConversationRequestPhase: Equatable {
    case idle
    case sending
    case streaming
    case error(message: String)

    var isInFlight: Bool {
        switch self {
        case .sending, .streaming:
            return true
        case .idle, .error:
            return false
        }
    }

    var errorMessage: String? {
        if case let .error(message) = self {
            return message
        }
        return nil
    }
}

@MainActor
final class UIState: ObservableObject {
    @Published private(set) var conversations: [Conversation] = []
    @Published var selectedConversationID: Conversation.ID?
    @Published var searchQuery: String = ""
    @Published private var conversationDrafts: [Conversation.ID: String] = [:]
    @Published var homeDraft: String = ""
    @Published var isAssistantTyping: Bool = false
    @Published var isStreamingResponse: Bool = false
    @Published var activeModelId: String
    @Published var errorMessage: String?
    
    // Remote backend support
    @Published private(set) var availableModels: [ChatModel] = []
    @Published private(set) var isLoadingModels: Bool = false
    @Published private(set) var isLoadingConversations: Bool = false
    @Published private(set) var hasMoreConversations: Bool = true
    
    // Per-conversation request phases
    @Published private var requestPhaseById: [UUID: ConversationRequestPhase] = [:]
    @Published private var pendingNewConversationPhase: ConversationRequestPhase = .idle
    
    // Pagination cursors
    private var conversationCursor: String?
    private var messagesCursorById: [UUID: String?] = [:]

    private let store: ConversationsUIStore?
    private let repo: ConversationsRepository?
    private let chatService: ChatService?

    // Remote-backend initializer
    init(repo: ConversationsRepository, chatService: ChatService) {
        self.repo = repo
        self.chatService = chatService
        self.store = nil
        self.activeModelId = "gpt-4"
        
        Task {
            await loadInitial()
        }
    }
    
    // Mock store initializer for previews
    init(store: ConversationsUIStore) {
        self.store = store
        self.repo = nil
        self.chatService = nil
        self.availableModels = store.availableModels
        self.activeModelId = store.availableModels.first?.id ?? "gpt-4"
        loadConversations()
    }

    convenience init() {
        self.init(store: MockConversationsStore())
    }

    var pinnedConversations: [Conversation] {
        filteredConversations(includingPinned: true)
    }

    var recentConversations: [Conversation] {
        filteredConversations(includingPinned: false)
    }

    var homeComposerPhase: ConversationRequestPhase {
        pendingNewConversationPhase
    }

    // MARK: - Initial Load (Remote)
    
    func loadInitial() async {
        guard let repo = repo else { return }

        isLoadingModels = true
        isLoadingConversations = true

        do {
            defer { isLoadingModels = false }
            let models = try await repo.fetchModels()
            availableModels = models
            if activeModelId.isEmpty, let first = models.first {
                activeModelId = first.id
            }
        } catch {
            handleError(error)
        }

        do {
            defer { isLoadingConversations = false }
            let result = try await repo.listConversations(limit: 10, cursor: nil)
            conversations = result.items
            conversationCursor = result.nextCursor
            hasMoreConversations = result.nextCursor != nil
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Load More (Pagination)
    
    func loadMoreConversations() async {
        guard let repo = repo,
              !isLoadingConversations,
              hasMoreConversations,
              let cursor = conversationCursor else {
            return
        }
        
        isLoadingConversations = true
        
        do {
            let result = try await repo.listConversations(limit: 10, cursor: cursor)
            conversations.append(contentsOf: result.items)
            conversationCursor = result.nextCursor
            hasMoreConversations = result.nextCursor != nil
        } catch {
            handleError(error)
        }
        
        isLoadingConversations = false
    }
    
    func loadMoreMessages(conversationId: UUID) async {
        guard let repo = repo,
              let cursor = messagesCursorById[conversationId] ?? nil else {
            return
        }
        
        do {
            let result = try await repo.getMessages(conversationId: conversationId, limit: 30, cursor: cursor)
            
            // Prepend older messages
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                var conversation = conversations[index]
                conversation.messages.insert(contentsOf: result.items, at: 0)
                conversations[index] = conversation
                messagesCursorById[conversationId] = result.nextCursor
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Open Conversation (lazy load messages)
    
    func openConversation(id: UUID) async {
        guard let repo = repo else {
            // Fallback to local
            selectedConversationID = id
            return
        }
        
        selectedConversationID = id
        
        // Check if we already have messages
        if let conv = conversations.first(where: { $0.id == id }), !conv.messages.isEmpty {
            return
        }
        
        // Lazy load messages
        do {
            let result = try await repo.getMessages(conversationId: id, limit: 30, cursor: nil)
            if let index = conversations.firstIndex(where: { $0.id == id }) {
                var conversation = conversations[index]
                conversation.messages = result.items
                conversations[index] = conversation
                messagesCursorById[id] = result.nextCursor
            }
        } catch {
            handleError(error)
        }
    }
    
    func loadConversations() {
        guard let store = store else { return }
        conversations = store.fetchConversations()
        // Non selezionare automaticamente la prima conversazione all'avvio
        // Questo permette di mostrare la homepage invece di aprire una conversazione
        // guard selectedConversationID == nil else { return }
        // selectedConversationID = conversations.first?.id
    }

    func selectConversation(_ conversationID: Conversation.ID?) {
        selectedConversationID = conversationID
    }

    func beginNewChat() {
        homeDraft = ""
        selectedConversationID = nil
        setPendingPhase(.idle)
    }

    func conversation(with id: Conversation.ID) -> Conversation? {
        conversations.first(where: { $0.id == id })
    }

    func draft(for conversationID: Conversation.ID) -> String {
        conversationDrafts[conversationID] ?? ""
    }

    func setDraft(_ text: String, for conversationID: Conversation.ID) {
        conversationDrafts[conversationID] = text
    }

    @discardableResult
    func submit(text: String, in conversationID: Conversation.ID?) -> Conversation.ID? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return conversationID }

        // Remote backend
        if repo != nil, chatService != nil {
            Task {
                await submitRemote(text: trimmed, conversationID: conversationID)
            }
            
            // Clear drafts immediately for better UX
            if let id = conversationID {
                conversationDrafts[id] = ""
            } else {
                homeDraft = ""
            }
            
            return conversationID
        }
        
        // Local store fallback
        guard let store = store else { return conversationID }
        
        let message = Message(role: .user, text: trimmed)

        if let id = conversationID,
           let conversation = store.updateConversation(id: id, mutate: { $0.messages.append(message) }) {
            updateLocal(conversation)
            conversationDrafts[id] = ""
            selectedConversationID = id
            return id
        } else {
            let conversation = store.createConversation(initialMessage: message, modelId: activeModelId)
            homeDraft = ""
            updateLocal(conversation)
            selectedConversationID = conversation.id
            return conversation.id
        }
    }
    
    private func submitRemote(text: String, conversationID: UUID?) async {
        guard let repo = repo, let chatService = chatService else { return }
        
        let userMessage = Message(role: .user, text: text)
        var targetConvId = conversationID
        var placeholderId: UUID?
        
        if let id = targetConvId {
            setPhase(.sending, for: id)
        } else {
            setPendingPhase(.sending)
        }
        
        do {
            // Create conversation if needed
            if targetConvId == nil {
                let newConv = try await repo.createConversation(initialMessage: userMessage, modelId: activeModelId)
                updateLocal(newConv)
                selectedConversationID = newConv.id
                targetConvId = newConv.id
                setPendingPhase(.idle)
                setPhase(.sending, for: newConv.id)
            } else {
                // Add user message optimistically
                if let id = targetConvId, let index = conversations.firstIndex(where: { $0.id == id }) {
                    var conversation = conversations[index]
                    conversation.messages.append(userMessage)
                    conversations[index] = conversation
                }
            }
            
            guard let convId = targetConvId else {
                return
            }
            
            // Add placeholder assistant message
            let assistantPlaceholder = Message(id: UUID(), role: .assistant, text: "", isLoading: true)
            let currentPlaceholderId = assistantPlaceholder.id
            placeholderId = currentPlaceholderId
            if let index = conversations.firstIndex(where: { $0.id == convId }) {
                var conversation = conversations[index]
                conversation.messages.append(assistantPlaceholder)
                conversations[index] = conversation
            }
            
            setPhase(.streaming, for: convId)
            
            // Stream reply
            await chatService.streamReply(
                conversationId: convId,
                userText: text,
                onDelta: { [weak self] delta in
                    guard let self = self else { return }
                    self.updateMessage(in: convId, messageId: currentPlaceholderId) { message in
                        message.text += delta
                        message.isLoading = false
                    }
                },
                onDone: { [weak self] in
                    guard let self = self else { return }
                    self.setPhase(.idle, for: convId)
                    self.updateMessage(in: convId, messageId: currentPlaceholderId) { message in
                        message.isLoading = false
                    }
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    let friendly = self.friendlyErrorMessage(for: error)
                    self.setPhase(.error(message: friendly), for: convId)
                    self.markAssistantMessageAsError(conversationId: convId, messageId: currentPlaceholderId, error: error, overrideMessage: friendly)
                    self.handleError(error)
                }
            )
        } catch {
            let friendly = friendlyErrorMessage(for: error)
            if conversationID == nil {
                homeDraft = text
                setPendingPhase(.error(message: friendly))
            }
            if let convId = targetConvId {
                setPhase(.error(message: friendly), for: convId)
            }
            if let convId = targetConvId, let placeholderId {
                markAssistantMessageAsError(conversationId: convId, messageId: placeholderId, error: error, overrideMessage: friendly)
            }
            handleError(error)
        }
    }

    func appendAssistantMessage(_ text: String, to conversationID: Conversation.ID) {
        guard let store = store else { return }
        let message = Message(role: .assistant, text: text)
        guard let conversation = store.updateConversation(id: conversationID, mutate: { $0.messages.append(message) }) else {
            return
        }
        updateLocal(conversation)
    }

    func clearConversation(id: Conversation.ID) {
        guard let store = store else { return }
        guard let conversation = store.updateConversation(id: id, mutate: { $0.messages.removeAll() }) else {
            return
        }
        updateLocal(conversation)
    }

    func updateTitle(_ title: String, for conversationID: Conversation.ID) {
        if let repo = repo {
            Task {
                do {
                    let conversation = try await repo.updateConversation(id: conversationID, title: title, modelId: nil, isPinned: nil)
                    updateLocal(conversation)
                } catch {
                    handleError(error)
                }
            }
        } else if let store = store {
            guard let conversation = store.updateConversation(id: conversationID, mutate: { $0.title = title }) else {
                return
            }
            updateLocal(conversation)
        }
    }

    func deleteConversation(id: Conversation.ID) {
        if let repo = repo {
            Task {
                do {
                    try await repo.deleteConversation(id: id)
                    removeLocal(id: id)
                    if selectedConversationID == id {
                        selectedConversationID = conversations.first?.id
                    }
                } catch {
                    handleError(error)
                }
            }
        } else if let store = store {
            store.deleteConversation(id: id)
            removeLocal(id: id)
            if selectedConversationID == id {
                selectedConversationID = conversations.first?.id
            }
        }
    }

    func duplicateConversation(id: Conversation.ID) {
        if let repo = repo {
            Task {
                do {
                    let conversation = try await repo.duplicateConversation(id: id)
                    updateLocal(conversation)
                    selectedConversationID = conversation.id
                } catch {
                    handleError(error)
                }
            }
        } else if let store = store {
            guard let conversation = store.duplicateConversation(id: id) else { return }
            updateLocal(conversation)
            selectedConversationID = conversation.id
        }
    }

    func setPinned(_ isPinned: Bool, for id: Conversation.ID) {
        if let repo = repo {
            Task {
                do {
                    let conversation = try await repo.updateConversation(id: id, title: nil, modelId: nil, isPinned: isPinned)
                    updateLocal(conversation)
                } catch {
                    handleError(error)
                }
            }
        } else if let store = store {
            guard let conversation = store.updateConversation(id: id, mutate: { $0.isPinned = isPinned }) else {
                return
            }
            updateLocal(conversation)
        }
    }

    func updateModel(for conversationID: Conversation.ID, to modelId: String) {
        if let repo = repo {
            Task {
                do {
                    let conversation = try await repo.updateConversation(id: conversationID, title: nil, modelId: modelId, isPinned: nil)
                    updateLocal(conversation)
                } catch {
                    handleError(error)
                }
            }
        } else if let store = store {
            guard let conversation = store.updateConversation(id: conversationID, mutate: { $0.modelId = modelId }) else {
                return
            }
            updateLocal(conversation)
        }
    }

    func setActiveModel(_ modelID: String) {
        activeModelId = modelID
    }

    func stopStreaming() {
        // Legacy for store-based mode
        isAssistantTyping = false
        isStreamingResponse = false
        
        // Remote mode
        if let chatService = chatService {
            Task {
                await chatService.stopAll()
                if pendingNewConversationPhase.isInFlight {
                    pendingNewConversationPhase = .idle
                }
                requestPhaseById = requestPhaseById.mapValues { phase in
                    if phase.isInFlight {
                        return .idle
                    }
                    return phase
                }
                updateStreamingState()
            }
        }
    }
    
    func stopStreaming(for conversationId: UUID) {
        if let chatService = chatService {
            Task {
                await chatService.stop(conversationId: conversationId)
                setPhase(.idle, for: conversationId)
            }
        } else {
            setPhase(.idle, for: conversationId)
        }
    }
    
    func isStreaming(_ conversationId: UUID) -> Bool {
        phase(for: conversationId).isInFlight
    }

    func phase(for conversationId: UUID) -> ConversationRequestPhase {
        requestPhaseById[conversationId] ?? .idle
    }
    
    private func setPhase(_ phase: ConversationRequestPhase, for conversationId: UUID) {
        var phases = requestPhaseById
        if phase == .idle {
            phases.removeValue(forKey: conversationId)
        } else {
            phases[conversationId] = phase
        }
        requestPhaseById = phases
        updateStreamingState()
    }

    private func setPendingPhase(_ phase: ConversationRequestPhase) {
        pendingNewConversationPhase = phase
        updateStreamingState()
    }

    private func updateStreamingState() {
        let anyInFlight = pendingNewConversationPhase.isInFlight || requestPhaseById.values.contains { $0.isInFlight }
        let anyStreaming = requestPhaseById.values.contains {
            if case .streaming = $0 { return true }
            return false
        }
        isStreamingResponse = anyInFlight
        isAssistantTyping = anyStreaming
    }

    private func filteredConversations(includingPinned: Bool) -> [Conversation] {
        let base = conversations.filter { includingPinned ? $0.isPinned : !$0.isPinned }
        guard !searchQuery.isEmpty else {
            return base
        }

        let query = searchQuery.lowercased()
        return base.filter { conversation in
            let title = conversation.title.lowercased()
            let lastSnippet = conversation.lastMessageSnippet.lowercased()
            return title.contains(query) || lastSnippet.contains(query)
        }
    }

    private func updateLocal(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }
        conversations = sortConversations(conversations)
    }

    private func updateMessage(in conversationId: UUID, messageId: UUID, mutate: (inout Message) -> Void) {
        guard let conversationIndex = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        var conversation = conversations[conversationIndex]
        guard let messageIndex = conversation.messages.firstIndex(where: { $0.id == messageId }) else { return }
        mutate(&conversation.messages[messageIndex])
        conversations[conversationIndex] = conversation
    }

    private func markAssistantMessageAsError(conversationId: UUID, messageId: UUID, error: Error, overrideMessage: String? = nil) {
        let messageText = overrideMessage ?? friendlyErrorMessage(for: error)
        updateMessage(in: conversationId, messageId: messageId) { message in
            message.isLoading = false
            message.text = messageText
            message.errorDescription = messageText
        }
    }

    private func removeLocal(id: Conversation.ID) {
        conversations.removeAll { $0.id == id }
        if requestPhaseById[id] != nil {
            var phases = requestPhaseById
            phases.removeValue(forKey: id)
            requestPhaseById = phases
        }
        updateStreamingState()
    }

    private func sortConversations(_ items: [Conversation]) -> [Conversation] {
        items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.lastActivityDate > rhs.lastActivityDate
        }
    }
    
    private func friendlyErrorMessage(for error: Error) -> String {
        if let httpError = error as? HTTPError {
            switch httpError {
            case .networkError(let underlying):
                return friendlyErrorMessage(for: underlying)
            case .httpError(let statusCode, _):
                return "[!] Il server Python ha risposto con l'errore \(statusCode). Riprova piu' tardi."
            default:
                return "[!] \(httpError.localizedDescription)"
            }
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .cannotConnectToHost, .timedOut, .networkConnectionLost:
                return "[!] Impossibile comunicare con il servizio Python. Assicurati che sia in esecuzione e riprova."
            default:
                return "[!] Errore di rete: \(urlError.localizedDescription)"
            }
        }
        return "[!] \(error.localizedDescription)"
    }

    private func handleError(_ error: Error) {
        let message = friendlyErrorMessage(for: error)
        print("UIState Error: \(error)")
        errorMessage = message
    }
}

final class MockConversationsStore: ConversationsUIStore {
    private(set) var availableModels: [ChatModel]
    private var storage: [Conversation]

    init(now: Date = Date()) {
        let gpt4 = ChatModel(id: "gpt-4.1", displayName: "GPT-4.1", description: "Ragionamento avanzato, qualita piu alta")
        let gpt4oMini = ChatModel(id: "gpt-4o-mini", displayName: "GPT-4o mini", description: "Velocita elevata, costo ridotto")
        let gpt35 = ChatModel(id: "gpt-3.5", displayName: "GPT-3.5 Turbo", description: "Risposte rapide e leggere")
        let dalle = ChatModel(id: "dall-e-3", displayName: "DALL-E 3", description: "Generazione immagini creativa")

        availableModels = [gpt4, gpt4oMini, gpt35, dalle]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        storage = [
            Conversation(
                title: "Storyboard conferenza WWDC",
                modelId: gpt4.id,
                isPinned: true,
                createdAt: formatter.date(from: "2024-07-20 10:15") ?? now,
                updatedAt: formatter.date(from: "2024-07-21 17:45") ?? now,
                messages: [
                    Message(role: .user, text: "Immagina un'introduzione coinvolgente per la keynote della nostra conferenza."),
                    Message(role: .assistant, text: "Potresti aprire con una transizione fluida dal buio alla luce, accompagnata da un breve jingle che richiami il brand. Poi presenta in tre punti il tema chiave della giornata."),
                    Message(role: .user, text: "Dammi tre slogan brevi."),
                    Message(role: .assistant, text: "1. \"Costruiamo insieme il prossimo futuro\"\n2. \"Idee audaci, impatto reale\"\n3. \"Dove l'innovazione incontra il design\"")
                ]
            ),
            Conversation(
                title: "Refactor SwiftUI layout",
                modelId: gpt4oMini.id,
                isPinned: false,
                createdAt: formatter.date(from: "2024-08-12 09:30") ?? now,
                updatedAt: formatter.date(from: "2024-08-12 09:45") ?? now,
                messages: [
                    Message(role: .user, text: "Come posso strutturare una NavigationSplitView per mantenere lo stato sincronizzato?"),
                    Message(role: .assistant, text: "Usa un ObservableObject condiviso tramite environment e collega la selection al binding del NavigationSplitView. In questo modo sidebar e detail restano sincronizzati."),
                    Message(role: .user, text: "Hai un esempio di codice?"),
                    Message(role: .assistant, text: "Certo!\n```swift\nNavigationSplitView(selection: $selection) {\n    Sidebar(selection: $selection)\n} detail: {\n    DetailView(selection: selection)\n}\n```\nQuesto mantiene la selezione condivisa." )
                ]
            ),
            Conversation(
                title: "Prompt immagini packaging",
                modelId: dalle.id,
                isPinned: false,
                createdAt: formatter.date(from: "2024-09-01 14:10") ?? now,
                updatedAt: formatter.date(from: "2024-09-01 15:05") ?? now,
                messages: [
                    Message(role: .user, text: "Genera un prompt per un packaging sostenibile minimalista bianco e salvia."),
                    Message(role: .assistant, text: "Poster minimal con superficie ruvida, carta riciclata, logo centrato in sans-serif, palette bianco caldo e verde salvia." )
                ]
            )
        ]

        sortStorage()
    }

    func fetchConversations() -> [Conversation] {
        storage
    }

    func createConversation(initialMessage: Message?, modelId: String) -> Conversation {
        var conversation = Conversation(title: makeTitle(from: initialMessage?.text ?? "Nuova chat"), modelId: modelId)
        if let message = initialMessage {
            conversation.messages = [message]
        }
        storage.append(conversation)
        sortStorage()
        return conversation
    }

    func updateConversation(id: Conversation.ID, mutate: (inout Conversation) -> Void) -> Conversation? {
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return nil }
        mutate(&storage[index])
        storage[index].updatedAt = Date()
        sortStorage()
        return storage[index]
    }

    func deleteConversation(id: Conversation.ID) {
        storage.removeAll { $0.id == id }
    }

    func duplicateConversation(id: Conversation.ID) -> Conversation? {
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return nil }
        var duplicate = storage[index]
        duplicate.id = UUID()
        duplicate.title = duplicate.title.appending(" copy")
        duplicate.createdAt = Date()
        duplicate.updatedAt = Date()
        duplicate.isPinned = false
        storage.append(duplicate)
        sortStorage()
        return duplicate
    }

    private func sortStorage() {
        storage = storage.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.lastActivityDate > rhs.lastActivityDate
        }
    }

    private func makeTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Nuova chat" }
        let firstSentence = trimmed.split(separator: "\n").first ?? Substring(trimmed)
        let cleaned = firstSentence.prefix(60)
        return cleaned.count == trimmed.count ? String(cleaned) : String(cleaned) + "..."
    }
}
