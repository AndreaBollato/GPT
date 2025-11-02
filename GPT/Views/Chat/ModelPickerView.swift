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
                    menuRow(for: model)
                }
                .buttonStyle(.plain)
            }
        } label: {
            pickerLabel
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private func menuRow(for model: ChatModel) -> some View {
        HStack(alignment: .center, spacing: AppConstants.Spacing.md) {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                Text(model.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(model.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.subtleText)
                    .lineLimit(2)
            }

            Spacer(minLength: AppConstants.Spacing.sm)

            if model.id == selectedModelId {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.horizontal, AppConstants.Spacing.sm)
        .padding(.vertical, AppConstants.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(model.id == selectedModelId ? AppColors.professionalVioletSoft.opacity(0.7) : Color.clear)
        )
    }

    private var pickerLabel: some View {
        HStack(alignment: .center, spacing: AppConstants.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Modello")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.subtleText)
                Text(selectedModel?.displayName ?? "Seleziona modello")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer(minLength: AppConstants.Spacing.sm)

            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.subtleText)
                .padding(.leading, AppConstants.Spacing.xs)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, AppConstants.Spacing.sm)
        .background(
            LinearGradient(colors: [AppColors.controlBackground, AppColors.professionalVioletSoft.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.controlBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct ModelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelPickerView(selectedModelId: UIState().availableModels.first?.id ?? "") { _ in }
            .environmentObject(UIState())
    }
}
