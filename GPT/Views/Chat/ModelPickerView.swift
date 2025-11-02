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
            Section(header: menuHeader) {
                ForEach(uiState.availableModels) { model in
                    Button(action: { onSelect(model.id) }) {
                        menuRow(for: model)
                    }
                    .buttonStyle(.plain)
                }
            }
        } label: {
            pickerLabel
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private func menuRow(for model: ChatModel) -> some View {
        HStack(alignment: .center, spacing: AppConstants.Spacing.md) {
            modelBadge(for: model)

            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                Text(model.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(model.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.subtleText)
                    .lineLimit(2)
            }

            Spacer(minLength: AppConstants.Spacing.sm)

            if model.id == selectedModelId {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.horizontal, AppConstants.Spacing.md)
        .padding(.vertical, AppConstants.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(model.id == selectedModelId ? highlightColor(for: model).opacity(0.18) : Color.clear)
        )
    }

    private var pickerLabel: some View {
        VStack(spacing: AppConstants.Spacing.xs) {
            Text("Modello")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.subtleText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppConstants.Spacing.md) {
                if let selectedModel {
                    modelBadge(for: selectedModel)
                }

                VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                    Text(selectedModel?.displayName ?? "Seleziona modello")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    Text(selectedModel?.description ?? "Scegli una configurazione")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppColors.subtleText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.leading, AppConstants.Spacing.xs)
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.sm)
            .background(
                LinearGradient(colors: [AppColors.controlBackground.opacity(0.96), AppColors.professionalVioletSoft.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppColors.controlBorder.opacity(0.8), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .frame(maxWidth: 260)
    }

    private var menuHeader: some View {
        Label("Modelli disponibili", systemImage: "square.grid.2x2")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(AppColors.subtleText)
    }

    private func modelBadge(for model: ChatModel) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(highlightColor(for: model))
                .frame(width: 34, height: 34)
            Image(systemName: iconName(for: model))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
        }
    }

    private func highlightColor(for model: ChatModel) -> Color {
        let id = model.id.lowercased()
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

    private func iconName(for model: ChatModel) -> String {
        let id = model.id.lowercased()
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

struct ModelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelPickerView(selectedModelId: UIState().availableModels.first?.id ?? "") { _ in }
            .environmentObject(UIState())
    }
}
