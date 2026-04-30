import XCTest
@testable import ZedIPad

@MainActor
final class ZedIPadFinalTests: XCTestCase {

    // These are the final tests for iteration 120
    // They validate the complete ZedIPad application

    func testApplicationIsReady() {
        let state = AppState()
        XCTAssertNotNil(state.rootDirectory, "App should have sample content loaded")
        XCTAssertEqual(state.theme, .dark, "Default theme should be Zed Dark")
        XCTAssertEqual(state.fontSize, 13, "Default font size should be 13pt")
        XCTAssertFalse(state.showingCommandPalette)
    }

    func testSyntaxHighlightingAvailable() {
        let languages = Language.swift.rawValue
        XCTAssertFalse(languages.isEmpty)
        let hl = SyntaxHighlighter(theme: .dark)
        let tokens = hl.highlight("let x = 1", language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testFindAndReplaceAvailable() {
        let find = FindState()
        XCTAssertEqual(find.matchCount, 0)
        find.query = "test"
        let _ = find.search(in: "test value")
        XCTAssertEqual(find.matchCount, 1)
    }

    func testGoToLineAvailable() {
        let gts = GoToLineState()
        gts.show()
        gts.lineNumber = "10"
        XCTAssertEqual(gts.parsedLine, 10)
    }

    func testSplitEditorAvailable() {
        let split = SplitEditorState()
        let f = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        split.openSplit(f)
        XCTAssertTrue(split.isSplit)
    }

    func testFileBrowsingAvailable() {
        let root = FileNode.sampleRoot()
        XCTAssertNotNil(root.children)
        let filtered = root.filtered(by: ".swift")
        XCTAssertNotNil(filtered)
    }

    func testAllThemesAvailable() {
        let themes = ZedTheme.allCases
        XCTAssertEqual(themes.count, 4)
        for theme in themes {
            let hl = SyntaxHighlighter(theme: theme)
            _ = hl.highlight("let x = 1", language: .swift)
        }
    }

    func testCommandPaletteAvailable() {
        let commands = PaletteCommand.allCommands
        XCTAssertFalse(commands.isEmpty)
        XCTAssertGreaterThan(commands.count, 5)
    }

    func testAllFeaturesIntegrated() {
        let state = AppState()
        let root = state.rootDirectory!
        var files: [FileNode] = []
        func collect(_ n: FileNode) { if n.type == .file { files.append(n) }; n.children?.forEach { collect($0) } }
        collect(root)
        XCTAssertGreaterThan(files.count, 10, "Project should have 10+ sample files")
        let langs = Set(files.map { Language.detect(from: $0.fileExtension) })
        let knownLangs = langs.filter { $0 != .unknown }
        XCTAssertGreaterThan(knownLangs.count, 5, "Should detect 5+ distinct languages")
    }
}
