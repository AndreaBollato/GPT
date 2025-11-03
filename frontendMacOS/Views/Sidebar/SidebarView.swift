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
            .buttonStyle(AppButtonStyle(variant: .secondary, size: .small, isIconOnly: true))
            .keyboardShortcut(AppConstants.KeyboardShortcuts.newConversation)
            .help("Crea una nuova chat")
        }
    }

    private var searchField: some View {
        let isFocused = resolvedSearchFocus.wrappedValue

        return HStack(spacing: AppConstants.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .imageScale(.medium)
                .foregroundStyle(isFocused ? AppColors.accent : AppColors.subtleText)

            TextField("Cerca conversazioni", text: $uiState.searchQuery)
                .textFieldStyle(.plain)
                .focused(resolvedSearchFocus)

            if !uiState.searchQuery.isEmpty {
                Button {
                    uiState.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.medium)
                        .foregroundStyle(AppColors.subtleText)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, AppConstants.Spacing.sm + 2)
        .padding(.horizontal, AppConstants.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .fill(isFocused ? AppColors.controlBackground : AppColors.controlMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                .stroke(isFocused ? AppColors.accent : AppColors.controlBorder, lineWidth: isFocused ? 1.5 : 1)
        )
        .shadow(color: isFocused ? AppColors.accent.opacity(0.12) : .clear, radius: isFocused ? 10 : 0, x: 0, y: 4)
        .animation(AppConstants.Animation.easeInOut, value: isFocused)
        .animation(AppConstants.Animation.easeInOut, value: uiState.searchQuery.isEmpty)
    }

    private var conversationList: some View {
        List {
            if !uiState.pinnedConversations.isEmpty {
                Section("Pinned") {
                    ForEach(uiState.pinnedConversations) { conversation in
                        ConversationRowView(conversation: conversation, isSelected: uiState.selectedConversationID == conversation.id)
                            .tag(conversation.id)
                            .listRowInsets(EdgeInsets(top: AppConstants.Spacing.xs,
                                                     leading: AppConstants.Spacing.sm,
                                                     bottom: AppConstants.Spacing.xs,
                                                     trailing: AppConstants.Spacing.sm))
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                Task {
                                    await uiState.openConversation(id: conversation.id)
                                }
                            }
                    }
                }
            }

            Section("Recenti") {
                ForEach(uiState.recentConversations) { conversation in
                    ConversationRowView(conversation: conversation, isSelected: uiState.selectedConversationID == conversation.id)
                        .tag(conversation.id)
                        .listRowInsets(EdgeInsets(top: AppConstants.Spacing.xs,
                                                 leading: AppConstants.Spacing.sm,
                                                 bottom: AppConstants.Spacing.xs,
                                                 trailing: AppConstants.Spacing.sm))
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            Task {
                                await uiState.openConversation(id: conversation.id)
                            }
                        }
                        .onAppear {
                            // Trigger pagination when approaching the end
                            if conversation.id == uiState.recentConversations.last?.id {
                                Task {
                                    await uiState.loadMoreConversations()
                                }
                            }
                        }
                }
                
                if uiState.isLoadingConversations {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: AppConstants.Spacing.xs,
                                             leading: AppConstants.Spacing.sm,
                                             bottom: AppConstants.Spacing.xs,
                                             trailing: AppConstants.Spacing.sm))
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.sidebar)
        .listSectionSeparator(.hidden)
        .listRowSeparator(.hidden)
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
