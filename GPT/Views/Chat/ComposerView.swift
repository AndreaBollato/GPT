import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    var placeholder: String = "Scrivi il tuo messaggio"
    var isStreaming: Bool = false
    var onSubmit: () -> Void
    var onStop: () -> Void
    var focus: FocusState<Bool>.Binding?

    @State private var isHoveringSend: Bool = false
    @FocusState private var internalFocus: Bool

    private var isSendDisabled: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: AppConstants.Layout.composerMinHeight,
                               maxHeight: AppConstants.Layout.composerMaxHeight)
                        .padding(.horizontal, AppConstants.Spacing.sm)
                        .padding(.vertical, AppConstants.Spacing.sm)
                        .background(AppColors.chatBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous))
                        .focused(resolvedFocus)
                        .scrollContentBackground(.hidden)

                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(AppColors.subtleText)
                            .padding(.horizontal, AppConstants.Spacing.sm + 4)
                            .padding(.vertical, AppConstants.Spacing.sm + 2)
                    }
                }

                HStack(spacing: AppConstants.Spacing.md) {
                    if isStreaming {
                        Button(action: onStop) {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColors.accent)
                    }

                    Spacer()
                    Text("?? per inviare")
                        .font(AppTypography.badge)
                        .foregroundColor(AppColors.subtleText)
                    Button(action: onSubmit) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(isSendDisabled ? AppColors.subtleText : .white)
                            .padding(AppConstants.Spacing.sm)
                            .background(
                                Circle()
                                    .fill(isSendDisabled ? AppColors.divider : AppColors.accent)
                                    .shadow(color: AppColors.accent.opacity(isHoveringSend ? 0.25 : 0), radius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSendDisabled)
                    .keyboardShortcut(AppConstants.KeyboardShortcuts.sendMessage)
                    .onHover { hovering in
                        isHoveringSend = hovering
                    }
                }
            }
            .padding(AppConstants.Spacing.lg)
            .background(AppColors.chatBackground.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            )

            if isStreaming {
                typingIndicator
            }
        }
        .animation(AppConstants.Animation.easeInOut, value: isStreaming)
    }

    private var resolvedFocus: FocusState<Bool>.Binding {
        focus ?? $internalFocus
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
