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

    let availableModels: [ChatModel]

    private let store: ConversationsUIStore

    init(store: ConversationsUIStore) {
        self.store = store
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

    func loadConversations() {
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

    func appendAssistantMessage(_ text: String, to conversationID: Conversation.ID) {
        let message = Message(role: .assistant, text: text)
        guard let conversation = store.updateConversation(id: conversationID, mutate: { $0.messages.append(message) }) else {
            return
        }
        updateLocal(conversation)
    }

    func clearConversation(id: Conversation.ID) {
        guard let conversation = store.updateConversation(id: id, mutate: { $0.messages.removeAll() }) else {
            return
        }
        updateLocal(conversation)
    }

    func updateTitle(_ title: String, for conversationID: Conversation.ID) {
        guard let conversation = store.updateConversation(id: conversationID, mutate: { $0.title = title }) else {
            return
        }
        updateLocal(conversation)
    }

    func deleteConversation(id: Conversation.ID) {
        store.deleteConversation(id: id)
        removeLocal(id: id)
        if selectedConversationID == id {
            selectedConversationID = conversations.first?.id
        }
    }

    func duplicateConversation(id: Conversation.ID) {
        guard let conversation = store.duplicateConversation(id: id) else { return }
        updateLocal(conversation)
        selectedConversationID = conversation.id
    }

    func setPinned(_ isPinned: Bool, for id: Conversation.ID) {
        guard let conversation = store.updateConversation(id: id, mutate: { $0.isPinned = isPinned }) else {
            return
        }
        updateLocal(conversation)
    }

    func updateModel(for conversationID: Conversation.ID, to modelId: String) {
        guard let conversation = store.updateConversation(id: conversationID, mutate: { $0.modelId = modelId }) else {
            return
        }
        updateLocal(conversation)
    }

    func setActiveModel(_ modelID: String) {
        activeModelId = modelID
    }

    func stopStreaming() {
        isAssistantTyping = false
        isStreamingResponse = false
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

    private func removeLocal(id: Conversation.ID) {
        conversations.removeAll { $0.id == id }
    }

    private func sortConversations(_ items: [Conversation]) -> [Conversation] {
        items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.lastActivityDate > rhs.lastActivityDate
        }
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
