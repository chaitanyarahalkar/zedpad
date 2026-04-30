import XCTest
@testable import ZedIPad

@MainActor
final class EdgeCaseTests: XCTestCase {

    // MARK: - AppState edge cases

    func testOpenAndCloseAllFiles() {
        let state = AppState()
        let files = (0..<20).map { FileNode(name: "f\($0).swift", type: .file, path: "/f\($0).swift") }
        files.forEach { state.openFile($0) }
        XCTAssertEqual(state.openFiles.count, 20)
        files.forEach { state.closeFile($0) }
        XCTAssertTrue(state.openFiles.isEmpty)
        XCTAssertNil(state.activeFile)
    }

    func testRootDirectoryNilDoesNotCrash() {
        let state = AppState()
        state.rootDirectory = nil
        XCTAssertNil(state.rootDirectory)
    }

    // MARK: - FindState edge cases

    func testFindInEmptyString() {
        let state = FindState()
        state.query = "test"
        let ranges = state.search(in: "")
        XCTAssertEqual(ranges.count, 0)
        XCTAssertEqual(state.matchCount, 0)
    }

    func testFindLongQuery() {
        let state = FindState()
        state.query = String(repeating: "a", count: 1000)
        let ranges = state.search(in: "short text")
        XCTAssertEqual(ranges.count, 0)
    }

    func testFindUnicodeEmoji() {
        let state = FindState()
        state.query = "🎉"
        let ranges = state.search(in: "Party 🎉 Time 🎉 Now")
        XCTAssertEqual(ranges.count, 2)
    }

    func testReplaceAllReturnsZeroWhenNothingMatches() {
        let state = FindState()
        state.query = "xyz"
        state.replaceQuery = "abc"
        var text = "nothing to replace here"
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(text, "nothing to replace here")
    }

    // MARK: - SyntaxHighlighter edge cases

    func testHighlightSingleChar() {
        let hl = SyntaxHighlighter(theme: .dark)
        let tokens = hl.highlight("x", language: .swift)
        _ = tokens // no crash
    }

    func testHighlightOnlyNewlines() {
        let hl = SyntaxHighlighter(theme: .dark)
        let tokens = hl.highlight("\n\n\n\n\n", language: .swift)
        _ = tokens
    }

    func testHighlightVeryLongLine() {
        let hl = SyntaxHighlighter(theme: .dark)
        let longLine = "let x = " + String(repeating: "a", count: 10000)
        let tokens = hl.highlight(longLine, language: .swift)
        _ = tokens // no crash
    }

    // MARK: - FileNode edge cases

    func testFileNodeWithNilChildren() {
        let file = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        XCTAssertNil(file.children)
        XCTAssertEqual(file.type, .file)
    }

    func testDirectoryWithEmptyChildren() {
        let dir = FileNode(name: "empty", type: .directory, path: "/empty", children: [])
        XCTAssertNotNil(dir.children)
        XCTAssertTrue(dir.children!.isEmpty)
    }

    func testFileNodeWithSpecialCharactersInName() {
        let file = FileNode(name: "my-special_file.v2.0.swift", type: .file, path: "/special")
        XCTAssertEqual(file.fileExtension, "swift")
    }

    func testFileNodeWithNoExtension() {
        let file = FileNode(name: "Makefile", type: .file, path: "/Makefile")
        XCTAssertEqual(file.fileExtension, "")
        XCTAssertEqual(Language.detect(from: ""), .unknown)
    }

    // MARK: - GoToLineState edge cases

    func testGoToLineWithWhitespace() {
        let state = GoToLineState()
        state.lineNumber = " 42 "
        XCTAssertNil(state.parsedLine) // "42" with spaces is not a valid Int parse
    }

    func testGoToLineWithLeadingZero() {
        let state = GoToLineState()
        state.lineNumber = "007"
        XCTAssertEqual(state.parsedLine, 7)
    }
}
