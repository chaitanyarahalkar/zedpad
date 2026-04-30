import XCTest
@testable import ZedIPad

@MainActor
final class AppWorkflowTests: XCTestCase {

    func testCompleteEditWorkflow() {
        let state = AppState()
        // 1. Start fresh
        XCTAssertNil(state.activeFile)
        // 2. Open a file
        let file = FileNode(name: "work.swift", type: .file, path: "/work.swift",
                            content: "let x = 1")
        state.openFile(file)
        XCTAssertEqual(state.activeFile?.id, file.id)
        // 3. Edit content
        file.content = "let x = 42\nlet y = x * 2"
        XCTAssertTrue(file.content.contains("42"))
        // 4. Find in file
        let findState = FindState()
        findState.query = "let"
        let ranges = findState.search(in: file.content)
        XCTAssertEqual(ranges.count, 2)
        // 5. Replace
        findState.replaceQuery = "var"
        let count = findState.replaceAll(in: &file.content)
        XCTAssertEqual(count, 2)
        XCTAssertFalse(file.content.contains("let"))
        // 6. Close file
        state.closeFile(file)
        XCTAssertNil(state.activeFile)
    }

    func testSwitchThemesWhileFilesOpen() {
        let state = AppState()
        let files = (0..<3).map { FileNode(name: "f\($0).swift", type: .file, path: "/f\($0).swift") }
        files.forEach { state.openFile($0) }
        XCTAssertEqual(state.theme, .dark)
        state.toggleTheme()
        XCTAssertEqual(state.theme, .light)
        XCTAssertEqual(state.openFiles.count, 3)
        // Verify highlighting still works in new theme
        let hl = SyntaxHighlighter(theme: state.theme)
        let tokens = hl.highlight("let x = 1", language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testSearchAndHighlightWorkflow() {
        let state = AppState()
        let file = FileNode(name: "search.py", type: .file, path: "/search.py",
                            content: "def greet(name):\n    return f'Hello, {name}!'")
        state.openFile(file)
        // Find
        let findState = FindState()
        findState.query = "name"
        let ranges = findState.search(in: file.content)
        XCTAssertEqual(ranges.count, 2)
        // Highlight
        let hl = SyntaxHighlighter(theme: state.theme)
        let tokens = hl.highlight(file.content, language: .python)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testMultipleWorkflowsDoNotInterfere() {
        let state1 = AppState()
        let state2 = AppState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        state1.openFile(f1)
        state2.openFile(f2)
        state1.toggleTheme()
        XCTAssertEqual(state1.theme, .light)
        XCTAssertEqual(state2.theme, .dark) // independent
        XCTAssertEqual(state1.activeFile?.id, f1.id)
        XCTAssertEqual(state2.activeFile?.id, f2.id)
    }

    func testGoToLineWorkflow() {
        let gts = GoToLineState()
        XCTAssertFalse(gts.isVisible)
        gts.show()
        XCTAssertTrue(gts.isVisible)
        gts.lineNumber = "42"
        XCTAssertEqual(gts.parsedLine, 42)
        gts.hide()
        XCTAssertFalse(gts.isVisible)
        XCTAssertNil(gts.parsedLine)
    }
}
