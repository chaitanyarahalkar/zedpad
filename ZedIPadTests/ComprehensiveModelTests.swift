import XCTest
@testable import ZedIPad

@MainActor
final class ComprehensiveModelTests: XCTestCase {

    func testAppStateDefaultFontSize() {
        let state = AppState()
        XCTAssertEqual(state.fontSize, 13)
    }

    func testAppStateFontSizeRange() {
        let state = AppState()
        // Decrease to minimum
        for _ in 0..<20 { state.decreaseFontSize() }
        XCTAssertEqual(state.fontSize, 9)
        // Increase to maximum
        for _ in 0..<20 { state.increaseFontSize() }
        XCTAssertEqual(state.fontSize, 24)
    }

    func testFindStateReplaceQueryDefault() {
        let state = FindState()
        XCTAssertEqual(state.replaceQuery, "")
    }

    func testFindStateQueryAndReplace() {
        let state = FindState()
        state.query = "hello"
        state.replaceQuery = "world"
        XCTAssertEqual(state.query, "hello")
        XCTAssertEqual(state.replaceQuery, "world")
    }

    func testFileNodeDefaultContent() {
        let file = FileNode(name: "empty.swift", type: .file, path: "/empty.swift")
        XCTAssertEqual(file.content, "")
    }

    func testFileNodeWithContent() {
        let file = FileNode(name: "code.swift", type: .file, path: "/code.swift",
                            content: "let x = 1")
        XCTAssertEqual(file.content, "let x = 1")
    }

    func testGoToLineStateDefaultLineNumber() {
        let state = GoToLineState()
        XCTAssertEqual(state.lineNumber, "")
    }

    func testSplitEditorStateDefaultFalse() {
        let state = SplitEditorState()
        XCTAssertFalse(state.isSplit)
        XCTAssertNil(state.secondaryFile)
    }

    func testAppStateMaxRecentFiles() {
        XCTAssertEqual(AppState.maxRecentFiles, 10)
    }

    func testZedThemeCount() {
        XCTAssertEqual(ZedTheme.allCases.count, 4)
    }

    func testLanguageEnumDistinctValues() {
        let langs: [Language] = [.swift, .javascript, .typescript, .python, .rust,
                                  .markdown, .json, .yaml, .bash, .ruby, .html, .css,
                                  .go, .kotlin, .c, .cpp, .sql, .scala, .lua, .php, .r, .unknown]
        let rawValues = langs.map(\.rawValue)
        let unique = Set(rawValues)
        XCTAssertEqual(unique.count, langs.count, "All language raw values should be unique")
    }
}
