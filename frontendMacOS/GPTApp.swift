//
//  GPTApp.swift
//  GPT
//
//  Created by Andrea Bollato on 02/11/25.
//

import SwiftUI

@main
struct GPTApp: App {
    var body: some Scene {
        WindowGroup {
            if AppConstants.API.useRemoteBackend {
                AppRootView(uiState: createRemoteUIState())
            } else {
                AppRootView()
            }
        }
    }
    
    private func createRemoteUIState() -> UIState {
        guard let baseURL = URL(string: AppConstants.API.baseURL) else {
            fatalError("Invalid base URL: \(AppConstants.API.baseURL)")
        }
        
        let client = HTTPClient(baseURL: baseURL)
        let repo = RemoteConversationsRepository(client: client)
        let chatService = ChatService(repo: repo)
        
        return UIState(repo: repo, chatService: chatService)
    }
}
