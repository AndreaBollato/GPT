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
                    ChatView(conversation: conversation, onSearchTapped: { searchFocused = true })
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
    }

}

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
    }
}
