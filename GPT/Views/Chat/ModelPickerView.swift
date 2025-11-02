import SwiftUI

struct ModelPickerView: View {
    @EnvironmentObject private var uiState: UIState

    var selectedModelId: String
    var onSelect: (String) -> Void

    private var selectedModel: ChatModel? {
        uiState.availableModels.first(where: { $0.id == selectedModelId })
    }

    var body: some View {
        Menu {
            ForEach(uiState.availableModels) { model in
                Button(action: { onSelect(model.id) }) {
                    HStack(alignment: .top, spacing: AppConstants.Spacing.sm) {
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.xxs) {
                            Text(model.displayName)
                                .font(.headline)
                            Text(model.description)
                                .font(.subheadline)
                                .foregroundColor(AppColors.subtleText)
                        }
                        if model.id == selectedModelId {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: AppConstants.Spacing.xs) {
                Text(selectedModel?.displayName ?? "Seleziona modello")
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.subtleText)
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.sm)
            .background(AppColors.chatBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
    }
}

struct ModelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelPickerView(selectedModelId: UIState().availableModels.first?.id ?? "") { _ in }
            .environmentObject(UIState())
    }
}
