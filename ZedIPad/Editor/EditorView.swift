import SwiftUI

struct EditorView: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode
    @State private var showingFind: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            EditorTabBar(file: file)

            Divider()
                .background(appState.theme.borderColor)

            // Find bar
            if showingFind {
                FindBar(isVisible: $showingFind)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Divider()
                    .background(appState.theme.borderColor)
            }

            // Editor body
            CodeEditorBody(file: file)
        }
        .background(appState.theme.editorBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingFind.toggle()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(showingFind ? appState.theme.accentColor : appState.theme.primaryText)
                }
                .accessibilityLabel("Find in File")
            }
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditorTabBar: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(appState.openFiles) { openFile in
                    EditorTab(file: openFile, isActive: openFile.id == file.id)
                        .onTapGesture {
                            appState.openFile(openFile)
                        }
                }
            }
        }
        .background(appState.theme.tabBarBackground)
        .frame(height: 36)
    }
}

struct EditorTab: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: file.icon)
                .font(.system(size: 11))
                .foregroundColor(isActive ? appState.theme.accentColor : appState.theme.secondaryText)

            Text(file.name)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(isActive ? appState.theme.primaryText : appState.theme.secondaryText)

            Button {
                appState.closeFile(file)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(isActive ? appState.theme.activeTabBackground : appState.theme.inactiveTabBackground)
        .overlay(
            Rectangle()
                .fill(isActive ? appState.theme.accentColor : Color.clear)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct CodeEditorBody: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var file: FileNode
    @State private var scrollPosition: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                HighlightedCodeView(
                    text: file.content,
                    language: Language.detect(from: file.fileExtension),
                    theme: appState.theme
                )
                .padding(.vertical, 12)
                .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .topLeading)
            }
        }
        .background(appState.theme.editorBackground)
    }
}

struct HighlightedCodeView: View {
    let text: String
    let language: Language
    let theme: ZedTheme

    var body: some View {
        let lines = text.components(separatedBy: "\n")
        let highlighter = SyntaxHighlighter(theme: theme)
        let tokens = highlighter.highlight(text, language: language)

        HStack(alignment: .top, spacing: 0) {
            // Line numbers
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                    Text("\(index + 1)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(theme.lineNumberText)
                        .frame(minWidth: 40, alignment: .trailing)
                        .padding(.vertical, 1)
                }
            }
            .padding(.trailing, 16)
            .padding(.leading, 8)

            // Code content
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    CodeLineView(line: line, lineIndex: index, text: text, tokens: tokens, theme: theme)
                        .padding(.vertical, 1)
                }
            }
            .padding(.trailing, 24)
        }
    }
}

struct CodeLineView: View {
    let line: String
    let lineIndex: Int
    let text: String
    let tokens: [SyntaxToken]
    let theme: ZedTheme

    var body: some View {
        if line.isEmpty {
            Text(" ")
                .font(.system(size: 13, design: .monospaced))
        } else {
            attributedLine
        }
    }

    private var attributedLine: some View {
        Text(buildAttributedString())
            .font(.system(size: 13, design: .monospaced))
            .textSelection(.enabled)
    }

    private func buildAttributedString() -> AttributedString {
        // Find start index of this line in the full text
        let lineComponents = text.components(separatedBy: "\n")
        var charOffset = 0
        for i in 0..<lineIndex {
            charOffset += lineComponents[i].count + 1 // +1 for newline
        }

        guard charOffset <= text.count else {
            return AttributedString(line)
        }

        let lineStart = text.index(text.startIndex, offsetBy: min(charOffset, text.count))
        let lineEnd = text.index(lineStart, offsetBy: min(line.count, text.count - charOffset))
        let lineRange = lineStart..<lineEnd

        var result = AttributedString(line)

        // Apply default color
        result.foregroundColor = theme.primaryText

        // Apply syntax token colors for tokens that overlap this line
        for token in tokens {
            guard token.range.overlaps(lineRange) else { continue }
            let clampedStart = max(token.range.lowerBound, lineRange.lowerBound)
            let clampedEnd = min(token.range.upperBound, lineRange.upperBound)
            guard clampedStart < clampedEnd else { continue }

            let offsetStart = text.distance(from: lineStart, to: clampedStart)
            let offsetEnd = text.distance(from: lineStart, to: clampedEnd)
            guard offsetStart >= 0 && offsetEnd <= line.count && offsetStart < offsetEnd else { continue }

            let attrStart = result.index(result.startIndex, offsetByCharacters: offsetStart)
            let attrEnd = result.index(result.startIndex, offsetByCharacters: offsetEnd)
            result[attrStart..<attrEnd].foregroundColor = token.color
        }

        return result
    }
}
