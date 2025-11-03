import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    var placeholder: String = "Scrivi il tuo messaggio"
    var phase: ConversationRequestPhase = .idle
    var onSubmit: () -> Void
    var onStop: () -> Void
    var focus: FocusState<Bool>.Binding?

    @FocusState private var internalFocus: Bool

    private var isSendDisabled: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shouldDisableSendButton: Bool {
        phase.isInFlight || isSendDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            composerSurface
            footerControls
            statusIndicator
        }
        .animation(AppConstants.Animation.easeInOut, value: phase)
    }

    private var resolvedFocus: FocusState<Bool>.Binding {
        focus ?? $internalFocus
    }

    private var composerSurface: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            accessoryButton(systemName: "plus")

            textFieldStack

            HStack(spacing: AppConstants.Spacing.sm) {
                accessoryButton(systemName: "mic.fill")
                accessoryButton(systemName: "waveform")
            }

            sendButton
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, AppConstants.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppColors.controlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AppColors.controlBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
    }

    private var textFieldStack: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(AppColors.subtleText)
                    .padding(.horizontal, 2)
            }

#if os(macOS)
            if #available(macOS 13.0, *) {
                TextField("", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(AppTypography.messageBody)
                    .focused(resolvedFocus)
                    .lineLimit(1...6)
                    .frame(minHeight: 32)
            } else {
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .font(AppTypography.messageBody)
                    .focused(resolvedFocus)
                    .frame(minHeight: 32)
            }
#else
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(AppTypography.messageBody)
                .focused(resolvedFocus)
                .frame(minHeight: 32)
#endif
        }
        .padding(.vertical, AppConstants.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func accessoryButton(systemName: String) -> some View {
        Button(action: {}) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
        }
        .buttonStyle(AppButtonStyle(variant: .subtle, size: .small, isIconOnly: true))
        .contentShape(Rectangle())
    }

    private var sendButton: some View {
        Button(action: onSubmit) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 15, weight: .semibold))
        }
        .disabled(shouldDisableSendButton)
        .opacity(shouldDisableSendButton ? 0.4 : 1)
        .buttonStyle(AppButtonStyle(variant: .primary, size: .regular, isIconOnly: true))
        .keyboardShortcut(AppConstants.KeyboardShortcuts.sendMessage)
    }

    private var footerControls: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            if isStreamingPhase {
                Button(action: onStop) {
                    Label("Interrompi", systemImage: "stop.fill")
                }
                .buttonStyle(AppButtonStyle(variant: .destructive, size: .small))
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if isSendingPhase {
            progressIndicator(text: "Richiesta al servizio Python...")
        } else if isStreamingPhase {
            progressIndicator(text: "Assistente sta rispondendo...")
        } else if let errorMessage {
            errorIndicator(text: errorMessage)
        }
    }

    private func progressIndicator(text: String) -> some View {
        HStack(spacing: AppConstants.Spacing.xs) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .tint(AppColors.accent)
            Text(text)
                .font(AppTypography.badge)
                .foregroundColor(AppColors.subtleText)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
    }

    private func errorIndicator(text: String) -> some View {
        HStack(spacing: AppConstants.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.error)
            Text(sanitizedErrorMessage(text))
                .font(AppTypography.badge)
                .foregroundColor(AppColors.error)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
    }

    private func sanitizedErrorMessage(_ text: String) -> String {
        guard text.hasPrefix("[!]") else { return text }
        let trimmed = text.dropFirst(3).trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? text : String(trimmed)
    }

    private var isStreamingPhase: Bool {
        if case .streaming = phase { return true }
        return false
    }

    private var isSendingPhase: Bool {
        if case .sending = phase { return true }
        return false
    }

    private var errorMessage: String? {
        phase.errorMessage
    }
}

// struct ComposerView_Previews: PreviewProvider {
//     static var previews: some View {
//         StatefulPreviewWrapper("") { binding in
//             StructPreviewContainer {
//                 ComposerView(text: binding, onSubmit: {}, onStop: {})
//                     .padding()
//             }
//         }
//     }
// }

// MARK: - Helpers for previews

private struct StructPreviewContainer<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .background(AppColors.background)
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
