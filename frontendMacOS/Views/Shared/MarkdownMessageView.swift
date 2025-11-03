import SwiftUI

struct MarkdownMessageView: View {
    let text: String

    private var segments: [Segment] {
        MarkdownParser.parse(text: text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            ForEach(segments) { segment in
                switch segment.content {
                case .text(let attributed):
                    Text(attributed)
                        .font(AppTypography.messageBody)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .code(let code, let language):
                    CodeBlockView(code: code, language: language)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Parser

private struct Segment: Identifiable {
    enum Content {
        case text(AttributedString)
        case code(code: String, language: String?)
    }

    let id = UUID()
    let content: Content
}

private enum MarkdownParser {
    static func parse(text: String) -> [Segment] {
        guard text.contains("```") else {
            return [makeTextSegment(from: text)].compactMap { $0 }
        }

        var results: [Segment] = []
        let parts = text.components(separatedBy: "```")

        for (index, part) in parts.enumerated() {
            if index.isMultiple(of: 2) {
                if let segment = makeTextSegment(from: part) {
                    results.append(segment)
                }
            } else {
                let (language, code) = extractLanguageAndCode(from: part)
                let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedCode.isEmpty else { continue }
                results.append(Segment(content: .code(code: trimmedCode, language: language)))
            }
        }

        return results
    }

    private static func makeTextSegment(from raw: String) -> Segment? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true, interpretedSyntax: .full)
        let attributed = (try? AttributedString(markdown: raw, options: options)) ?? AttributedString(raw)
        return Segment(content: .text(attributed))
    }

    private static func extractLanguageAndCode(from raw: String) -> (String?, String) {
        if let newlineRange = raw.range(of: "\n") {
            let language = raw[..<newlineRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let code = String(raw[newlineRange.upperBound...])
            return (language.isEmpty ? nil : language, code)
        } else {
            return (nil, raw)
        }
    }
}

struct MarkdownMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MarkdownMessageView(text: """
        ## Titolo
        Questo ? un messaggio con **markdown**, elenco e codice.

        - Punto uno
        - Punto due

        ```swift
        let message = "Hello"
        print(message)
        ```
        """)
        .padding()
        .background(AppColors.assistantBubble)
    }
}
