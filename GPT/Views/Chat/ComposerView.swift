import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    var placeholder: String = "Scrivi il tuo messaggio"
    var isStreaming: Bool = false
    var onSubmit: () -> Void
    var onStop: () -> Void
    var focus: FocusState<Bool>.Binding?

    @FocusState private var internalFocus: Bool

    private var isSendDisabled: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            composerSurface
            footerControls

            if isStreaming {
                typingIndicator
            }
        }
        .animation(AppConstants.Animation.easeInOut, value: isStreaming)
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
        .disabled(isSendDisabled)
        .opacity(isSendDisabled ? 0.4 : 1)
        .buttonStyle(AppButtonStyle(variant: .primary, size: .regular, isIconOnly: true))
        .keyboardShortcut(AppConstants.KeyboardShortcuts.sendMessage)
    }

    private var footerControls: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            if isStreaming {
                Button(action: onStop) {
                    Label("Interrompi", systemImage: "stop.fill")
                }
                .buttonStyle(AppButtonStyle(variant: .destructive, size: .small))
            }

            Spacer()
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: AppConstants.Spacing.xs) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
            Text("Assistente sta rispondendo...")
                .font(AppTypography.badge)
                .foregroundColor(AppColors.subtleText)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
    }
}

struct ComposerView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper("") { binding in
            StructPreviewContainer {
                ComposerView(text: binding, onSubmit: {}, onStop: {})
                    .padding()
            }
        }
    }
}

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
