import SwiftUI

struct AppRootView: View {
    @StateObject private var uiState = UIState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(searchFocus: $searchFocused)
        } detail: {
            Group {
                if let selected = uiState.selectedConversationID,
                   let conversation = uiState.conversation(with: selected) {
                    ChatView(conversation: conversation)
                } else {
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
        }
        .environmentObject(uiState)
        .navigationSplitViewStyle(.balanced)
        .toolbar { toolbarContent }
        .background(AppColors.background)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button(action: uiState.beginNewChat) {
                Label("Nuova chat", systemImage: "plus")
            }
            .keyboardShortcut(AppConstants.KeyboardShortcuts.newConversation)

            Button(action: uiState.stopStreaming) {
                Label("Stop", systemImage: "stop.fill")
            }
            .keyboardShortcut(AppConstants.KeyboardShortcuts.stopStreaming)
            .disabled(!uiState.isStreamingResponse)

            Button {
                searchFocused = true
            } label: {
                Label("Cerca conversazioni", systemImage: "magnifyingglass")
            }
            .keyboardShortcut(AppConstants.KeyboardShortcuts.searchConversations)
        }
    }

}

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
    }
}
