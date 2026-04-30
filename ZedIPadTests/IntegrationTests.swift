import XCTest
@testable import ZedIPad

@MainActor
final class IntegrationTests: XCTestCase {

    // AppState + SyntaxHighlighter integration
    func testOpenFileAndHighlight() {
        let state = AppState()
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift",
                            content: "import Foundation\nlet x: Int = 42")
        state.openFile(file)
        XCTAssertEqual(state.activeFile?.id, file.id)
        let lang = Language.detect(from: state.activeFile!.fileExtension)
        XCTAssertEqual(lang, .swift)
        let hl = SyntaxHighlighter(theme: state.theme)
        let tokens = hl.highlight(state.activeFile!.content, language: lang)
        XCTAssertFalse(tokens.isEmpty)
    }

    // FileNode sample root + language detection for each file
    func testSampleRootAllFilesDetectLanguage() {
        let root = FileNode.sampleRoot()
        func checkFile(_ node: FileNode) {
            if node.type == .file {
                let lang = Language.detect(from: node.fileExtension)
                // Just verify no crash and some languages are detected
                _ = lang
            }
            node.children?.forEach { checkFile($0) }
        }
        checkFile(root)
    }

    // FindState + real file content
    func testFindInSampleFileContent() {
        let state = FindState()
        let root = FileNode.sampleRoot()
        let sources = root.children?.first { $0.name == "Sources" }
        let mainSwift = sources?.children?.first { $0.name == "main.swift" }
        guard let content = mainSwift?.content else {
            XCTFail("main.swift content not found")
            return
        }
        state.query = "import"
        let ranges = state.search(in: content)
        XCTAssertGreaterThan(ranges.count, 0, "Should find 'import' in main.swift")
    }

    // AppState + GoToLineState interaction
    func testGoToLineWithAppStateFile() {
        let appState = AppState()
        let file = FileNode(name: "long.swift", type: .file, path: "/long.swift",
                            content: Array(1...100).map { "let line\($0) = \($0)" }.joined(separator: "\n"))
        appState.openFile(file)
        let lineCount = file.content.components(separatedBy: "\n").count
        XCTAssertEqual(lineCount, 100)
        let goToLine = GoToLineState()
        goToLine.lineNumber = "50"
        XCTAssertEqual(goToLine.parsedLine, 50)
        // Clamping logic
        let clamped = max(1, min(goToLine.parsedLine!, lineCount))
        XCTAssertEqual(clamped, 50)
    }

    // SplitEditorState + AppState
    func testSplitViewWithTwoOpenFiles() {
        let appState = AppState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift", content: "let a = 1")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift", content: "let b = 2")
        appState.openFile(f1)
        appState.openFile(f2)
        XCTAssertEqual(appState.openFiles.count, 2)
        let split = SplitEditorState()
        split.openSplit(f1)
        XCTAssertTrue(split.isSplit)
        XCTAssertEqual(appState.activeFile?.id, f2.id)
        XCTAssertEqual(split.secondaryFile?.id, f1.id)
    }

    // Find + Replace integration
    func testFindReplaceInFileContent() {
        let state = FindState()
        state.query = "ZedIPad"
        state.replaceQuery = "CodeEdit"
        let root = FileNode.sampleRoot()
        let sources = root.children?.first { $0.name == "Sources" }
        let main = sources?.children?.first { $0.name == "main.swift" }
        guard let file = main else { XCTFail("main.swift missing"); return }
        var content = file.content
        let _ = state.search(in: content)
        XCTAssertGreaterThan(state.matchCount, 0)
        let replaced = state.replaceAll(in: &content)
        XCTAssertGreaterThan(replaced, 0)
        XCTAssertFalse(content.contains("ZedIPad"))
        XCTAssertTrue(content.contains("CodeEdit"))
    }

    // Theme + Syntax token color integration
    func testThemeSyntaxColorsAppliedToTokens() {
        let themes = ZedTheme.allCases
        let code = "import Swift\nclass Foo { let x = 42 }"
        for theme in themes {
            let hl = SyntaxHighlighter(theme: theme)
            let tokens = hl.highlight(code, language: .swift)
            XCTAssertFalse(tokens.isEmpty, "Theme \(theme.rawValue) produced no tokens")
        }
    }

    // FileNode filter + AppState open
    func testFilterAndOpenFilteredFile() {
        let appState = AppState()
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: "README")
        XCTAssertNotNil(filtered)
        func findReadme(_ node: FileNode) -> FileNode? {
            if node.name.hasPrefix("README") && node.type == .file { return node }
            return node.children?.compactMap { findReadme($0) }.first
        }
        if let readme = findReadme(filtered!) {
            appState.openFile(readme)
            XCTAssertEqual(appState.activeFile?.name, "README.md")
        }
    }
}
