import XCTest
@testable import ZedIPad

@MainActor
final class FinalSummaryTests: XCTestCase {

    func testProjectVersionMetadata() {
        // Verify basic project information is accessible
        XCTAssertFalse(ZedTheme.dark.rawValue.isEmpty)
        XCTAssertEqual(AppState.maxRecentFiles, 10)
    }

    func testHighlighterDoesNotRetainState() {
        // Two separate highlighter instances on same code should produce same result
        let code = "let x = 42"
        let hl1 = SyntaxHighlighter(theme: .dark)
        let hl2 = SyntaxHighlighter(theme: .dark)
        let t1 = hl1.highlight(code, language: .swift)
        let t2 = hl2.highlight(code, language: .swift)
        XCTAssertEqual(t1.count, t2.count)
    }

    func testLanguageEnumCoverage() {
        let allCases: [Language] = [.swift, .javascript, .typescript, .python, .rust,
                                     .markdown, .json, .yaml, .bash, .ruby, .html, .css,
                                     .go, .kotlin, .c, .cpp, .sql, .scala, .lua, .php,
                                     .r, .unknown]
        XCTAssertEqual(allCases.count, 22)
        // All should have a raw value
        for lang in allCases {
            XCTAssertFalse(lang.rawValue.isEmpty)
        }
    }

    func testFindStateDefaultsCorrect() {
        let state = FindState()
        XCTAssertEqual(state.query, "")
        XCTAssertEqual(state.replaceQuery, "")
        XCTAssertEqual(state.matchCount, 0)
        XCTAssertEqual(state.currentMatch, 0)
        XCTAssertFalse(state.isCaseSensitive)
        XCTAssertFalse(state.isRegex)
        XCTAssertFalse(state.showReplace)
    }

    func testGoToLineDefaultsCorrect() {
        let state = GoToLineState()
        XCTAssertFalse(state.isVisible)
        XCTAssertEqual(state.lineNumber, "")
        XCTAssertNil(state.parsedLine)
    }

    func testSplitEditorDefaultsCorrect() {
        let state = SplitEditorState()
        XCTAssertFalse(state.isSplit)
        XCTAssertNil(state.secondaryFile)
    }

    func testFileNodeDefaultsCorrect() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift")
        XCTAssertFalse(file.id.uuidString.isEmpty)
        XCTAssertEqual(file.name, "test.swift")
        XCTAssertEqual(file.type, .file)
        XCTAssertEqual(file.path, "/test.swift")
        XCTAssertNil(file.children)
        XCTAssertFalse(file.isExpanded)
        XCTAssertEqual(file.content, "")
        XCTAssertEqual(file.fileExtension, "swift")
    }

    func testAppStateDefaultsCorrect() {
        let state = AppState()
        XCTAssertNil(state.activeFile)
        XCTAssertTrue(state.openFiles.isEmpty)
        XCTAssertTrue(state.recentFiles.isEmpty)
        XCTAssertEqual(state.theme, .dark)
        XCTAssertFalse(state.showingCommandPalette)
        XCTAssertNotNil(state.rootDirectory)
        XCTAssertEqual(state.fontSize, 13)
    }
}
