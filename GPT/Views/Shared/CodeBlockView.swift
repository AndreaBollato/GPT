import SwiftUI

struct CodeBlockView: View {
    let code: String
    var language: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack {
                Text(languageLabel)
                    .font(AppTypography.badge)
                    .foregroundColor(AppColors.subtleText)
                    .textCase(.uppercase)
                Spacer()
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
}

struct CodeBlockView_Previews: PreviewProvider {
    static var previews: some View {
        CodeBlockView(code: "let greeting = \"Hello ChatGPT\"\nprint(greeting)", language: "swift")
            .previewLayout(.sizeThatFits)
            .padding()
            .background(AppColors.chatBackground)
    }
}
