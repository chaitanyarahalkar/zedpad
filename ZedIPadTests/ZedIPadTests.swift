import XCTest
@testable import ZedIPad

@MainActor
final class SyntaxHighlighterTests: XCTestCase {
    let darkTheme = ZedTheme.dark
    let lightTheme = ZedTheme.light

    func testSwiftHighlightingKeywords() {
        let highlighter = SyntaxHighlighter(theme: darkTheme)
        let code = "import SwiftUI\nstruct MyView: View {}"
        let tokens = highlighter.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty, "Should produce tokens for Swift code")
    }

    func testHighlightingProducesStringTokens() {
        let highlighter = SyntaxHighlighter(theme: darkTheme)
        let code = "let greeting = \"Hello, World!\""
        let tokens = highlighter.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testLanguageDetection() {
        XCTAssertEqual(Language.detect(from: "swift"), .swift)
        XCTAssertEqual(Language.detect(from: "js"), .javascript)
        XCTAssertEqual(Language.detect(from: "py"), .python)
        XCTAssertEqual(Language.detect(from: "rs"), .rust)
        XCTAssertEqual(Language.detect(from: "md"), .markdown)
        XCTAssertEqual(Language.detect(from: "json"), .json)
        XCTAssertEqual(Language.detect(from: "xyz"), .unknown)
    }

    func testThemeColors() {
        XCTAssertNotEqual(darkTheme.background, lightTheme.background)
        XCTAssertNotEqual(darkTheme.primaryText, lightTheme.primaryText)
    }

    func testColorScheme() {
        XCTAssertEqual(darkTheme.colorScheme, .dark)
        XCTAssertEqual(lightTheme.colorScheme, .light)
        XCTAssertEqual(ZedTheme.oneDark.colorScheme, .dark)
        XCTAssertEqual(ZedTheme.solarizedDark.colorScheme, .dark)
    }

    func testAllThemesAvailable() {
        XCTAssertEqual(ZedTheme.allCases.count, 4)
    }

    func testFileNodeSampleRoot() {
        let root = FileNode.sampleRoot()
        XCTAssertEqual(root.type, .directory)
        XCTAssertFalse(root.children?.isEmpty ?? true)
    }

    func testFileNodeExtension() {
        let swiftFile = FileNode(name: "main.swift", type: .file, path: "/main.swift")
        XCTAssertEqual(swiftFile.fileExtension, "swift")
        let noExt = FileNode(name: "Makefile", type: .file, path: "/Makefile")
        XCTAssertEqual(noExt.fileExtension, "")
    }

    @MainActor func testPaletteCommandsNotEmpty() {
        XCTAssertFalse(PaletteCommand.allCommands.isEmpty)
    }

    func testHighlightEmptyString() {
        let highlighter = SyntaxHighlighter(theme: darkTheme)
        let tokens = highlighter.highlight("", language: .swift)
        XCTAssertTrue(tokens.isEmpty)
    }

    func testHighlightPython() {
        let highlighter = SyntaxHighlighter(theme: darkTheme)
        let code = "def hello():\n    print(\"hello\")\n    return True"
        let tokens = highlighter.highlight(code, language: .python)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightRust() {
        let highlighter = SyntaxHighlighter(theme: darkTheme)
        let code = "fn main() {\n    let x: i32 = 42;\n    println!(\"{}\", x);\n}"
        let tokens = highlighter.highlight(code, language: .rust)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testFindStateSearch() {
        let state = FindState()
        state.query = "hello"
        let text = "hello world, say hello again"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 2)
        XCTAssertEqual(state.matchCount, 2)
    }

    func testFindStateCaseInsensitive() {
        let state = FindState()
        state.query = "HELLO"
        state.isCaseSensitive = false
        let ranges = state.search(in: "hello Hello HELLO")
        XCTAssertEqual(ranges.count, 3)
    }

    func testFindStateCaseSensitive() {
        let state = FindState()
        state.query = "HELLO"
        state.isCaseSensitive = true
        let ranges = state.search(in: "hello Hello HELLO")
        XCTAssertEqual(ranges.count, 1)
    }

    func testFindStateNavigation() {
        let state = FindState()
        state.query = "x"
        let _ = state.search(in: "x x x")
        XCTAssertEqual(state.matchCount, 3)
        state.nextMatch()
        XCTAssertEqual(state.currentMatch, 1)
        state.previousMatch()
        XCTAssertEqual(state.currentMatch, 0)
    }

    func testFindStateEmptyQuery() {
        let state = FindState()
        state.query = ""
        let ranges = state.search(in: "some text")
        XCTAssertTrue(ranges.isEmpty)
        XCTAssertEqual(state.matchCount, 0)
    }
}
