import SwiftUI

struct EditorView: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode
    @State private var showingFind: Bool = false
    @State private var saveError: String? = nil
    @StateObject private var goToLine = GoToLineState()

    private var lineCount: Int { file.content.components(separatedBy: "\n").count }

    var body: some View {
        VStack(spacing: 0) {
            EditorTabBar(file: file)

            Divider()
                .background(appState.theme.borderColor)

            if showingFind {
                FindBar(isVisible: $showingFind, file: file)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Divider()
                    .background(appState.theme.borderColor)
            }

            if goToLine.isVisible {
                GoToLineView(state: goToLine, totalLines: lineCount) { _ in }
                    .transition(.move(edge: .top).combined(with: .opacity))
                Divider()
                    .background(appState.theme.borderColor)
            }

            BreadcrumbView(file: file)

            EditableCodeEditor(file: file)

            StatusBar(file: file, text: file.content)
        }
        .background(appState.theme.editorBackground)
        .overlay(alignment: .topLeading) {
            FindShortcutButton(showFind: $showingFind)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    // Undo via UITextView undoManager
                    UIApplication.shared.sendAction(#selector(UndoManager.undo), to: nil, from: nil, for: nil)
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(appState.theme.primaryText)
                }
                .accessibilityLabel("Undo")
                .keyboardShortcut("z", modifiers: .command)

                Button {
                    UIApplication.shared.sendAction(#selector(UndoManager.redo), to: nil, from: nil, for: nil)
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .foregroundColor(appState.theme.primaryText)
                }
                .accessibilityLabel("Redo")
                .keyboardShortcut("z", modifiers: [.command, .shift])

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingFind.toggle()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(showingFind ? appState.theme.accentColor : appState.theme.primaryText)
                }
                .accessibilityLabel("Find in File")
                .keyboardShortcut("f", modifiers: .command)

                if file.fileURL != nil {
                    Button {
                        saveFile()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: file.isDirty ? "square.and.arrow.down.fill" : "square.and.arrow.down")
                                .foregroundColor(file.isDirty ? appState.theme.accentColor : appState.theme.secondaryText)
                        }
                    }
                    .accessibilityLabel("Save File")
                    .keyboardShortcut("s", modifiers: .command)
                }
            }
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveFile() {
        guard let url = file.fileURL else { return }
        do {
            try file.content.write(to: url, atomically: true, encoding: .utf8)
            file.isDirty = false
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - Tab Bar

struct EditorTabBar: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(appState.openFiles) { openFile in
                    EditorTab(file: openFile, isActive: openFile.id == file.id)
                        .onTapGesture { appState.openFile(openFile) }
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

// MARK: - Editable Editor

struct EditableCodeEditor: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var file: FileNode
    @State private var scrollFraction: CGFloat = 0
    @State private var showMinimap: Bool = true

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                // Line numbers gutter
                LineNumberGutter(text: file.content, theme: appState.theme)
                    .frame(width: 52)

                Divider()
                    .background(appState.theme.borderColor)

                // Editable text area with live syntax highlighting
                SyntaxHighlightingTextView(
                    text: Binding(
                        get: { file.content },
                        set: { file.content = $0 }
                    ),
                    language: Language.detect(from: file.fileExtension),
                    theme: appState.theme,
                    fontSize: appState.fontSize,
                    tabSize: appState.tabSize,
                    wordWrap: appState.wordWrap,
                    highlightRanges: appState.findHighlightRanges,
                    scrollToRange: appState.findScrollToRange
                )
                .frame(minWidth: max(geo.size.width - 52 - (showMinimap ? 80 : 0), 100),
                       minHeight: geo.size.height)

                // Minimap
                if showMinimap {
                    MinimapView(
                        text: file.content,
                        language: Language.detect(from: file.fileExtension),
                        scrollFraction: $scrollFraction
                    )
                }
            }
        }
        .background(appState.theme.editorBackground)
    }
}

// MARK: - Line Number Gutter

struct LineNumberGutter: View {
    let text: String
    let theme: ZedTheme

    private var lineCount: Int {
        text.components(separatedBy: "\n").count
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...max(lineCount, 1), id: \.self) { line in
                    Text("\(line)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(theme.lineNumberText)
                        .padding(.vertical, 1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .background(theme.sidebarBackground)
        .disabled(true)
    }
}

// MARK: - Highlighted Code View (read-only, used in search preview)

struct HighlightedCodeView: View {
    let text: String
    let language: Language
    let theme: ZedTheme

    var body: some View {
        let lines = text.components(separatedBy: "\n")
        let highlighter = SyntaxHighlighter(theme: theme)
        let tokens = highlighter.highlight(text, language: language)

        HStack(alignment: .top, spacing: 0) {
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
            Text(" ").font(.system(size: 13, design: .monospaced))
        } else {
            Text(buildAttributedString())
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func buildAttributedString() -> AttributedString {
        let lineComponents = text.components(separatedBy: "\n")
        var charOffset = 0
        for i in 0..<lineIndex {
            charOffset += lineComponents[i].count + 1
        }
        guard charOffset <= text.count else { return AttributedString(line) }
        let lineStart = text.index(text.startIndex, offsetBy: min(charOffset, text.count))
        let lineEnd = text.index(lineStart, offsetBy: min(line.count, text.count - charOffset))
        let lineRange = lineStart..<lineEnd

        var result = AttributedString(line)
        result.foregroundColor = theme.primaryText

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
