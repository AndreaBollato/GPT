import SwiftUI

// MARK: - ChatModel Helper Extensions
extension ChatModel {
    var highlightColor: Color {
        let id = self.id.lowercased()
        if id.contains("mini") {
            return Color.orange
        }
        if id.contains("dall") {
            return Color.pink
        }
        if id.contains("3.5") {
            return Color.blue
        }
        return AppColors.accent
    }

    var iconName: String {
        let id = self.id.lowercased()
        if id.contains("mini") {
            return "bolt"
        }
        if id.contains("dall") {
            return "paintpalette"
        }
        if id.contains("3.5") {
            return "bubble.left.and.sparkles"
        }
        return "sparkles"
    }
}

struct ModelPickerView: View {
    @EnvironmentObject private var uiState: UIState

    var selectedModelId: String
    var onSelect: (String) -> Void

    @State private var isOpen: Bool = false

    private var selectedModel: ChatModel? {
        uiState.availableModels.first(where: { $0.id == selectedModelId })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Bottone che apre/chiude il menu e mostra la selezione corrente
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.18)) { 
                    isOpen.toggle() 
                } 
            }) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(selectedModel?.displayName ?? "Seleziona modello")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        if let description = selectedModel?.description {
                            Text(description)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Se la selezione esiste mostriamo checkmark
                    if selectedModel != nil {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.accent)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(nsColor: NSColor.windowBackgroundColor))
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Menù custom
            if isOpen {
                VStack(spacing: 0) {
                    ForEach(uiState.availableModels.indices, id: \.self) { index in
                        let model = uiState.availableModels[index]
                        ModelRow(model: model,
                                 isSelected: model.id == selectedModelId) {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                onSelect(model.id)
                                isOpen = false
                            }
                        }
                        .background(Color.clear)
                        if index < uiState.availableModels.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(nsColor: NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(nsColor: NSColor.separatorColor).opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: 360)
    }
}

// MARK: - Riga singolo elemento aggiornata per evidenziare la selezione e hover
struct ModelRow: View {
    @EnvironmentObject private var uiState: UIState
    
    var model: ChatModel
    var isSelected: Bool
    var action: () -> Void

    @State private var isHovering: Bool = false
    
    private var backgroundColor: Color {
        if isSelected {
            return AppColors.accent.opacity(0.10)
        } else if isHovering {
            return Color(nsColor: NSColor.selectedControlColor).opacity(0.06)
        } else {
            return Color.clear
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Indicatore verticale a sinistra quando selezionato
                Rectangle()
                    .fill(AppColors.accent)
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .opacity(isSelected ? 1 : 0)

                // Icona sinistra
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: NSColor.windowBackgroundColor))
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(nsColor: NSColor.separatorColor).opacity(0.08), lineWidth: 1)
                        )

                    Image(systemName: model.iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(model.highlightColor)
                }

                // Titolo e sottotitolo
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(model.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Checkmark quando selezionato
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                self.isHovering = hovering
            }
        }
    }
}

struct ModelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ModelPickerView(selectedModelId: UIState().availableModels.first?.id ?? "") { _ in }
                .environmentObject(UIState())
                .padding(24)
                .frame(width: 420)
                .previewDisplayName("Light")
            
            ModelPickerView(selectedModelId: UIState().availableModels.first?.id ?? "") { _ in }
                .environmentObject(UIState())
                .padding(24)
                .frame(width: 420)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}
