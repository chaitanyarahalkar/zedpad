import XCTest
@testable import ZedIPad

@MainActor
final class FinalCoverageTests: XCTestCase {

    func testAllModelsInitialize() {
        let appState = AppState()
        let findState = FindState()
        let goToLine = GoToLineState()
        let splitState = SplitEditorState()
        let fileNode = FileNode(name: "test.swift", type: .file, path: "/test.swift")
        XCTAssertNotNil(appState); XCTAssertNotNil(findState)
        XCTAssertNotNil(goToLine); XCTAssertNotNil(splitState)
        XCTAssertNotNil(fileNode)
    }

    func testAllThemeColorsAccessible() {
        for theme in ZedTheme.allCases {
            _ = theme.background; _ = theme.sidebarBackground; _ = theme.editorBackground
            _ = theme.primaryText; _ = theme.secondaryText; _ = theme.lineNumberText
            _ = theme.accentColor; _ = theme.selectionColor; _ = theme.borderColor
            _ = theme.tabBarBackground; _ = theme.activeTabBackground; _ = theme.inactiveTabBackground
            _ = theme.syntaxKeyword; _ = theme.syntaxString; _ = theme.syntaxComment
            _ = theme.syntaxFunction; _ = theme.syntaxType; _ = theme.syntaxNumber
            _ = theme.findHighlight; _ = theme.colorScheme
        }
    }

    func testSyntaxHighlighterWithAllLanguages() {
        let code = "test code 123 \"string\" // comment\n#hash\n/* block */"
        for theme in ZedTheme.allCases {
            let hl = SyntaxHighlighter(theme: theme)
            let langs: [Language] = [.swift, .python, .javascript, .rust, .go,
                                      .ruby, .php, .sql, .scala, .lua, .r,
                                      .html, .css, .yaml, .bash, .c, .cpp,
                                      .kotlin, .typescript, .json, .markdown, .unknown]
            for lang in langs {
                _ = hl.highlight(code, language: lang)
            }
        }
    }

    func testFileNodeFilterChain() {
        let root = FileNode.sampleRoot()
        let f1 = root.filtered(by: "swift")
        let f2 = root.filtered(by: ".swift")
        let f3 = root.filtered(by: "json")
        XCTAssertNotNil(f1); XCTAssertNotNil(f2); XCTAssertNotNil(f3)
    }

    func testFindStateFullWorkflow() {
        let state = FindState()
        let text = "Hello World Hello Swift Hello iPad"
        state.query = "Hello"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 3)
        XCTAssertEqual(state.matchCount, 3)
        state.nextMatch(); XCTAssertEqual(state.currentMatch, 1)
        state.nextMatch(); XCTAssertEqual(state.currentMatch, 2)
        state.nextMatch(); XCTAssertEqual(state.currentMatch, 0) // wrap
        state.previousMatch(); XCTAssertEqual(state.currentMatch, 2) // wrap back
        state.replaceQuery = "Hi"
        var mutableText = text
        let count = state.replaceAll(in: &mutableText)
        XCTAssertEqual(count, 3)
        XCTAssertFalse(mutableText.contains("Hello"))
    }

    func testGoToLineFullWorkflow() {
        let state = GoToLineState()
        state.show()
        XCTAssertTrue(state.isVisible)
        state.lineNumber = "42"
        XCTAssertEqual(state.parsedLine, 42)
        state.hide()
        XCTAssertFalse(state.isVisible)
        XCTAssertNil(state.parsedLine)
    }

    func testSplitEditorFullWorkflow() {
        let split = SplitEditorState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        split.openSplit(f1)
        XCTAssertTrue(split.isSplit)
        split.openSplit(f2) // replace
        XCTAssertEqual(split.secondaryFile?.id, f2.id)
        var p: FileNode? = f1
        var s: FileNode? = f2
        split.swapEditors(primary: &p, secondary: &s)
        XCTAssertEqual(p?.id, f2.id)
        XCTAssertEqual(s?.id, f1.id)
        split.closeSplit()
        XCTAssertFalse(split.isSplit)
    }
}
