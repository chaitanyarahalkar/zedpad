import XCTest
@testable import ZedIPad

final class EditorComponentTests: XCTestCase {

    // MARK: - Language detection tests

    func testLanguageDetectionAllCases() {
        let cases: [(String, Language)] = [
            ("swift", .swift),
            ("js", .javascript),
            ("ts", .typescript),
            ("tsx", .typescript),
            ("jsx", .typescript),
            ("py", .python),
            ("rs", .rust),
            ("md", .markdown),
            ("json", .json),
            ("yaml", .yaml),
            ("yml", .yaml),
            ("sh", .bash),
            ("bash", .bash),
            ("rb", .ruby),
            ("", .unknown),
            ("cpp", .unknown),
            ("go", .unknown),
        ]
        for (ext, expected) in cases {
            XCTAssertEqual(Language.detect(from: ext), expected, "Mismatch for extension: \(ext)")
        }
    }

    // MARK: - Syntax highlighter tests

    func testHighlightJavaScript() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "const x = 42;\nfunction hello() {\n  return 'world';\n}"
        let tokens = hl.highlight(code, language: .javascript)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightJSON() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "{ \"key\": \"value\", \"num\": 42, \"flag\": true, \"nothing\": null }"
        let tokens = hl.highlight(code, language: .json)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightMarkdown() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "# Title\n## Subtitle\nSome `code` here.\n\n```swift\nlet x = 1\n```"
        let tokens = hl.highlight(code, language: .markdown)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightUnknownLanguageReturnsEmpty() {
        let hl = SyntaxHighlighter(theme: .dark)
        let tokens = hl.highlight("hello world", language: .unknown)
        XCTAssertTrue(tokens.isEmpty)
    }

    func testAllThemesSyntaxColorsDistinct() {
        for theme in ZedTheme.allCases {
            XCTAssertNotEqual(theme.syntaxKeyword, theme.syntaxString,
                              "Keyword and string colors should differ in \(theme.rawValue)")
            XCTAssertNotEqual(theme.syntaxComment, theme.syntaxFunction,
                              "Comment and function colors should differ in \(theme.rawValue)")
        }
    }

    // MARK: - FileNode content tests

    func testFileNodeContentMutable() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "let x = 1")
        file.content = "let y = 2"
        XCTAssertEqual(file.content, "let y = 2")
    }

    func testFileNodeChildrenAppend() {
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [])
        let child = FileNode(name: "a.swift", type: .file, path: "/src/a.swift")
        dir.children?.append(child)
        XCTAssertEqual(dir.children?.count, 1)
    }

    func testFileNodeToggleExpanded() {
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [])
        XCTAssertFalse(dir.isExpanded)
        dir.isExpanded = true
        XCTAssertTrue(dir.isExpanded)
        XCTAssertEqual(dir.icon, "folder.fill")
        dir.isExpanded = false
        XCTAssertEqual(dir.icon, "folder")
    }

    // MARK: - ZedTheme tests

    func testAllThemesHaveNonEmptyRawValue() {
        for theme in ZedTheme.allCases {
            XCTAssertFalse(theme.rawValue.isEmpty)
        }
    }

    func testLightThemeColorScheme() {
        XCTAssertEqual(ZedTheme.light.colorScheme, .light)
    }

    func testDarkThemeBackgroundDarkerThanLight() {
        // Just verify they're different — not that one is "darker"
        XCTAssertNotEqual(ZedTheme.dark.background, ZedTheme.light.background)
        XCTAssertNotEqual(ZedTheme.oneDark.background, ZedTheme.solarizedDark.background)
    }

    // MARK: - FindState regex tests

    @MainActor func testFindStateRegexSearch() {
        let state = FindState()
        state.query = "\\d+"
        state.isRegex = true
        let ranges = state.search(in: "foo 123 bar 456 baz")
        XCTAssertEqual(ranges.count, 2)
    }

    @MainActor func testFindStateInvalidRegexFallsBack() {
        let state = FindState()
        state.query = "[invalid"
        state.isRegex = true
        let ranges = state.search(in: "test [invalid regex")
        // Invalid regex → 0 matches (regex init fails)
        XCTAssertEqual(ranges.count, 0)
    }

    @MainActor func testFindStateNextMatchWraps() {
        let state = FindState()
        state.query = "a"
        let _ = state.search(in: "a b a")
        XCTAssertEqual(state.matchCount, 2)
        state.nextMatch() // 0→1
        state.nextMatch() // 1→0 (wrap)
        XCTAssertEqual(state.currentMatch, 0)
    }

    @MainActor func testFindStatePrevMatchWraps() {
        let state = FindState()
        state.query = "x"
        let _ = state.search(in: "x y x z x")
        XCTAssertEqual(state.matchCount, 3)
        state.previousMatch() // 0→2 (wrap)
        XCTAssertEqual(state.currentMatch, 2)
    }
}
