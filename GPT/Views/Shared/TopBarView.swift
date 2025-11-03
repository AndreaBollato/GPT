import SwiftUI

struct TopBarView: View {
    struct Status {
        let text: String
        let color: Color
    }

    var title: String?
    var status: Status?

    var selectedModelId: String
    var onSelectModel: (String) -> Void

    var onNewChat: () -> Void
    var onSearch: () -> Void
    var onDuplicate: (() -> Void)?
    var onDelete: (() -> Void)?

    var isStreaming: Bool = false
    var onStopStreaming: (() -> Void)?

    var body: some View {
        ZStack {
            HStack(spacing: AppConstants.Spacing.lg) {
                ModelPickerView(selectedModelId: selectedModelId, onSelect: onSelectModel)
                    .frame(minWidth: 220, alignment: .leading)

                Spacer(minLength: AppConstants.Spacing.md)

                actionButtons
            }

            if let title {
                VStack(spacing: AppConstants.Spacing.xs) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    if let status {
                        statusLabel(for: status)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppConstants.Spacing.xl)
        .padding(.vertical, AppConstants.Spacing.lg)
        .background(AppColors.background)
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            if isStreaming, let onStopStreaming {
                iconButton(systemName: "stop.fill", variant: .destructive, help: "Interrompi risposta", shortcut: AppConstants.KeyboardShortcuts.stopStreaming, action: onStopStreaming)
            }

            iconButton(systemName: "plus", help: "Nuova chat", shortcut: AppConstants.KeyboardShortcuts.newConversation, action: onNewChat)

            iconButton(systemName: "magnifyingglass", help: "Cerca conversazioni", shortcut: AppConstants.KeyboardShortcuts.searchConversations, action: onSearch)

            if let onDuplicate {
                iconButton(systemName: "square.on.square", help: "Duplica conversazione", action: onDuplicate)
            }

            if let onDelete {
                iconButton(systemName: "trash", variant: .destructive, help: "Elimina conversazione", action: onDelete)
            }
        }
    }

    private func iconButton(systemName: String,
                            variant: AppButtonStyle.Variant = .secondary,
                            help: String? = nil,
                            shortcut: KeyboardShortcut? = nil,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
        }
        .appButtonStyle(variant, iconOnly: true)
        .optionalHelp(help)
        .optionalShortcut(shortcut)
    }

    private func statusLabel(for status: Status) -> some View {
        HStack(spacing: AppConstants.Spacing.xs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(status.text)
                .font(AppTypography.badge)
                .foregroundStyle(AppColors.subtleText)
        }
    }
}

private extension View {
    @ViewBuilder
    func optionalShortcut(_ shortcut: KeyboardShortcut?) -> some View {
        if let shortcut {
            self.keyboardShortcut(shortcut)
        } else {
            self
        }
    }

    @ViewBuilder
    func optionalHelp(_ help: String?) -> some View {
        if let help {
            self.help(help)
        } else {
            self
        }
    }
}

