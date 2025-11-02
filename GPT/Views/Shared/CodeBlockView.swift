import SwiftUI
import AppKit

struct CodeBlockView: View {
    let code: String
    var language: String?

    @State private var isCopied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack {
                Text(languageLabel)
                    .font(AppTypography.badge)
                    .foregroundColor(AppColors.subtleText)
                    .textCase(.uppercase)
                Spacer()
                Button(action: copyToPasteboard) {
                    Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .labelStyle(.iconOnly)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundColor(isCopied ? AppColors.accent : AppColors.subtleText)
                .help(isCopied ? "Copied" : "Copy to clipboard")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(AppTypography.messageMono)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppConstants.Spacing.lg)
        .background(AppColors.codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius, style: .continuous))
    }

    private var languageLabel: String {
        guard let language, !language.isEmpty else { return "code" }
        return language.uppercased()
    }

    private func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)

        withAnimation(AppConstants.Animation.easeInOut) {
            isCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(AppConstants.Animation.easeInOut) {
                isCopied = false
            }
        }
    }
}

struct CodeBlockView_Previews: PreviewProvider {
    static var previews: some View {
        CodeBlockView(code: "let greeting = \"Hello ChatGPT\"\nprint(greeting)", language: "swift")
            .previewLayout(.sizeThatFits)
            .padding()
            .background(AppColors.chatBackground)
    }
}
