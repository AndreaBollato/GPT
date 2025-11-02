import SwiftUI

struct AppRootView: View {
    @StateObject private var uiState: UIState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @FocusState private var searchFocused: Bool
    
    init(uiState: UIState) {
        _uiState = StateObject(wrappedValue: uiState)
    }
    
    init() {
        _uiState = StateObject(wrappedValue: UIState())
    }

    var body: some View {
        ZStack(alignment: .top) {
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
            
            // Error banner
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

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
    }
}
