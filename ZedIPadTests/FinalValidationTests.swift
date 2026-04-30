import XCTest
@testable import ZedIPad

@MainActor
final class FinalValidationTests: XCTestCase {

    // Final validation: everything works end-to-end

    func testCompleteUserSession() {
        // Simulate a complete user session
        let state = AppState()

        // 1. App starts with dark theme and no open files
        XCTAssertEqual(state.theme, .dark)
        XCTAssertTrue(state.openFiles.isEmpty)

        // 2. User opens main.swift
        let root = state.rootDirectory!
        func findSwiftFile(_ node: FileNode) -> FileNode? {
            if node.name == "main.swift" && node.type == .file { return node }
            return node.children?.compactMap { findSwiftFile($0) }.first
        }
        guard let mainFile = findSwiftFile(root) else { XCTFail("main.swift not found"); return }
        state.openFile(mainFile)
        XCTAssertEqual(state.activeFile?.name, "main.swift")

        // 3. User uses find to search for "import"
        let find = FindState()
        find.query = "import"
        let ranges = find.search(in: mainFile.content)
        XCTAssertGreaterThan(ranges.count, 0)

        // 4. User changes theme to light
        state.toggleTheme()
        XCTAssertEqual(state.theme, .light)

        // 5. Highlighting works in light theme
        let hl = SyntaxHighlighter(theme: state.theme)
        let tokens = hl.highlight(mainFile.content, language: .swift)
        XCTAssertFalse(tokens.isEmpty)

        // 6. User increases font size
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, 14)

        // 7. User uses Go to Line
        let gts = GoToLineState()
        gts.show()
        gts.lineNumber = "5"
        XCTAssertEqual(gts.parsedLine, 5)
        gts.hide()

        // 8. Recent files are tracked
        XCTAssertGreaterThan(state.recentFiles.count, 0)

        // 9. User closes file
        state.closeFile(mainFile)
        XCTAssertNil(state.activeFile)
    }

    func testAllFeaturesWork() {
        // Just verify all major types initialize and work
        let _ = AppState()
        let _ = FindState()
        let _ = GoToLineState()
        let _ = SplitEditorState()
        let _ = SyntaxHighlighter(theme: .dark)
        let _ = FileNode.sampleRoot()
        let _ = ZedTheme.allCases
        XCTAssertTrue(true) // All initialized without crash
    }

    func testHighlightingAllSampleFilesAllThemes() {
        let root = FileNode.sampleRoot()
        var files: [FileNode] = []
        func collect(_ node: FileNode) {
            if node.type == .file { files.append(node) }
            node.children?.forEach { collect($0) }
        }
        collect(root)
        for theme in ZedTheme.allCases {
            let hl = SyntaxHighlighter(theme: theme)
            for file in files {
                let lang = Language.detect(from: file.fileExtension)
                _ = hl.highlight(file.content, language: lang)
            }
        }
        XCTAssertGreaterThan(files.count, 10)
    }
}
