import XCTest
@testable import ZedIPad

@MainActor
final class ViewModelConsistencyTests: XCTestCase {

    func testAppStateThemeConsistency() {
        let state = AppState()
        let themes = ZedTheme.allCases
        for theme in themes {
            state.theme = theme
            XCTAssertEqual(state.theme, theme)
            XCTAssertEqual(state.theme.colorScheme == .dark || state.theme.colorScheme == .light, true)
        }
    }

    func testFindStateQueryUpdateReflected() {
        let state = FindState()
        let queries = ["hello", "world", "swift", "ipad", "zed", ""]
        for query in queries {
            state.query = query
            XCTAssertEqual(state.query, query)
        }
    }

    func testGoToLineStateLineNumberUpdateReflected() {
        let state = GoToLineState()
        let values = ["1", "100", "999", "0", "-1", "abc", ""]
        for val in values {
            state.lineNumber = val
            XCTAssertEqual(state.lineNumber, val)
        }
    }

    func testSplitEditorStateConsistency() {
        let state = SplitEditorState()
        let files = (0..<3).map { FileNode(name: "v\($0).swift", type: .file, path: "/v\($0).swift") }
        for file in files {
            state.openSplit(file)
            XCTAssertEqual(state.secondaryFile?.id, file.id)
            XCTAssertTrue(state.isSplit)
        }
        state.closeSplit()
        XCTAssertFalse(state.isSplit)
        XCTAssertNil(state.secondaryFile)
    }

    func testFileNodePropertyConsistency() {
        let cases: [(String, FileNodeType)] = [
            ("main.swift", .file),
            ("src", .directory),
            ("data.json", .file),
            ("lib", .directory),
        ]
        for (name, type) in cases {
            let node = FileNode(name: name, type: type, path: "/\(name)",
                                children: type == .directory ? [] : nil)
            XCTAssertEqual(node.name, name)
            XCTAssertEqual(node.type, type)
            XCTAssertFalse(node.icon.isEmpty)
        }
    }

    func testHighlighterWithAllThemesAndLanguages() {
        let langs: [Language] = [.swift, .python, .javascript, .rust, .go]
        let code = "x = 42"
        for theme in ZedTheme.allCases {
            let hl = SyntaxHighlighter(theme: theme)
            for lang in langs {
                let tokens = hl.highlight(code, language: lang)
                _ = tokens
            }
        }
    }
}
