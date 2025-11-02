import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var uiState: UIState
    @FocusState private var composerFocused: Bool

    private let prompts: [SuggestedPrompt] = SuggestedPrompt.samples

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xxl) {
                    hero
                    suggestedPrompts
                }
                .padding(.top, 80)
                .padding(.bottom, 220)
                .frame(maxWidth: AppConstants.Layout.detailMaxWidth)
                .frame(maxWidth: .infinity)
            }

            ComposerView(
                text: $uiState.homeDraft,
                placeholder: "Inizia una nuova conversazione",
                isStreaming: uiState.isStreamingResponse,
                onSubmit: submitFromHome,
                onStop: uiState.stopStreaming,
                focus: $composerFocused
            )
            .padding(.horizontal, 80)
            .padding(.vertical, AppConstants.Spacing.xl)
            .background(
                LinearGradient(
                    colors: [AppColors.background.opacity(0.95), AppColors.background.opacity(0.6), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .background(AppColors.background)
        .onAppear {
            composerFocused = true
        }
    }

    private var hero: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Text("Come posso aiutarti oggi?")
                .font(AppTypography.heroTitle)
                .foregroundColor(.primary)
            Text("Scegli un prompt suggerito oppure scrivi la tua domanda per iniziare una nuova chat.")
                .font(AppTypography.heroSubtitle)
                .foregroundColor(AppColors.subtleText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var suggestedPrompts: some View {
        let columns = [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: AppConstants.Spacing.lg)]

        return LazyVGrid(columns: columns, spacing: AppConstants.Spacing.lg) {
            ForEach(prompts) { prompt in
                Button {
                    uiState.homeDraft = prompt.text
                    composerFocused = true
                } label: {
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                        Text(prompt.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(prompt.text)
                            .font(.subheadline)
                            .foregroundColor(AppColors.subtleText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(AppConstants.Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.chatBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                            .stroke(AppColors.divider, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppConstants.Spacing.xl)
    }

    private func submitFromHome() {
        let newConversationID = uiState.submit(text: uiState.homeDraft, in: nil)
        if let id = newConversationID {
            uiState.selectConversation(id)
        }
        composerFocused = true
    }
}

private struct SuggestedPrompt: Identifiable {
    let id = UUID()
    let title: String
    let text: String

    static let samples: [SuggestedPrompt] = [
        SuggestedPrompt(title: "Brainstorm di idee", text: "Suggerisci concept per una landing page SaaS che promuove l'IA generativa."),
        SuggestedPrompt(title: "Tutorial", text: "Spiega come usare NavigationSplitView in un progetto SwiftUI con esempi di codice."),
        SuggestedPrompt(title: "Verifica codice", text: "Revisiona questa funzione Swift per capire se ci sono bug o edge case."),
        SuggestedPrompt(title: "Marketing copy", text: "Scrivi un'email di lancio per una nuova funzionalit? di automazione delle chat."),
        SuggestedPrompt(title: "Sintesi", text: "Riassumi i punti principali di questa trascrizione di meeting in bullet point."),
        SuggestedPrompt(title: "Analisi dati", text: "Descrivi come potrei analizzare i log di utilizzo per estrarre insight rilevanti."),
    ]
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(UIState())
    }
}
