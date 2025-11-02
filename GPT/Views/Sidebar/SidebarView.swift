import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var uiState: UIState
    private var searchFocus: FocusState<Bool>.Binding?
    @FocusState private var internalSearchFocus: Bool

    init(searchFocus: FocusState<Bool>.Binding? = nil) {
        self.searchFocus = searchFocus
    }

    var body: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            header
            searchField
            conversationList
        }
        .padding(AppConstants.Spacing.lg)
        .frame(minWidth: AppConstants.Layout.sidebarMinWidth,
               idealWidth: AppConstants.Layout.sidebarIdealWidth,
               maxWidth: AppConstants.Layout.sidebarMaxWidth,
               maxHeight: .infinity, alignment: .top)
        .background(AppColors.sidebarBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppColors.sidebarBorder)
                .frame(width: 1)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack {
            Text("Conversazioni")
                .font(.headline)
            Spacer()
            Button(action: uiState.beginNewChat) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(AppColors.accent)
            .keyboardShortcut(AppConstants.KeyboardShortcuts.newConversation)
            .help("Crea una nuova chat")
        }
    }

    private var searchField: some View {
        TextField("Cerca conversazioni", text: $uiState.searchQuery)
            .textFieldStyle(.roundedBorder)
            .focused(resolvedSearchFocus)
            .overlay(alignment: .trailing) {
                if !uiState.searchQuery.isEmpty {
                    Button {
                        uiState.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.subtleText)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, AppConstants.Spacing.xs)
                }
            }
    }

    private var conversationList: some View {
        List(selection: $uiState.selectedConversationID) {
            if !uiState.pinnedConversations.isEmpty {
                Section("Pinned") {
                    ForEach(uiState.pinnedConversations) { conversation in
                        ConversationRowView(conversation: conversation, isSelected: uiState.selectedConversationID == conversation.id)
                            .tag(conversation.id)
                            .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Recenti") {
                ForEach(uiState.recentConversations) { conversation in
                    ConversationRowView(conversation: conversation, isSelected: uiState.selectedConversationID == conversation.id)
                        .tag(conversation.id)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppColors.sidebarBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resolvedSearchFocus: FocusState<Bool>.Binding {
        searchFocus ?? $internalSearchFocus
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(UIState())
            .frame(width: 300)
    }
}
