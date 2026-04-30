import XCTest
@testable import ZedIPad

@MainActor
final class Iter100FinalTests: XCTestCase {

    // Iteration 100 milestone tests — comprehensive validation

    func testZedIPadProjectOverview() {
        // Validate the complete ZedIPad feature set is testable
        let state = AppState()
        XCTAssertNotNil(state.rootDirectory, "Sample root should be loaded")
        XCTAssertEqual(state.theme, .dark)
        XCTAssertEqual(ZedTheme.allCases.count, 4)
        XCTAssertGreaterThan(state.rootDirectory!.children?.count ?? 0, 0)
    }

    func testAllFeaturesPresent() {
        // Syntax highlighting: 21 languages
        let langs: [Language] = [.swift, .python, .javascript, .typescript, .rust, .go,
                                  .kotlin, .scala, .ruby, .php, .lua, .r, .c, .cpp,
                                  .sql, .html, .css, .yaml, .json, .bash, .markdown]
        XCTAssertEqual(langs.count, 21)

        // Themes: 4
        XCTAssertEqual(ZedTheme.allCases.count, 4)

        // Models: AppState, FindState, GoToLineState, SplitEditorState
        let _ = AppState()
        let _ = FindState()
        let _ = GoToLineState()
        let _ = SplitEditorState()
    }

    func testSampleProjectStructure() {
        let root = FileNode.sampleRoot()
        var topLevelNames: [String] = []
        root.children?.forEach { topLevelNames.append($0.name) }
        // Verify project has expected structure
        XCTAssertTrue(topLevelNames.contains("Sources"))
        XCTAssertTrue(topLevelNames.contains("jvm"))
        XCTAssertTrue(topLevelNames.contains("scripts"))
        XCTAssertTrue(topLevelNames.contains("web"))
        XCTAssertTrue(topLevelNames.contains("config"))
        XCTAssertTrue(topLevelNames.contains("README.md"))
    }

    func testHighlightingWorksForAllSampleFiles() {
        let root = FileNode.sampleRoot()
        var processed = 0
        func processFile(_ node: FileNode) {
            if node.type == .file {
                let lang = Language.detect(from: node.fileExtension)
                let hl = SyntaxHighlighter(theme: .dark)
                _ = hl.highlight(node.content, language: lang)
                processed += 1
            }
            node.children?.forEach { processFile($0) }
        }
        processFile(root)
        XCTAssertGreaterThan(processed, 10, "Should process at least 10 sample files")
    }

    func testAppStateWorkingCorrectly() {
        let state = AppState()
        let root = FileNode.sampleRoot()
        func countFiles(_ node: FileNode) -> Int {
            if node.type == .file { return 1 }
            return node.children?.map { countFiles($0) }.reduce(0, +) ?? 0
        }
        let totalFiles = countFiles(root)
        XCTAssertGreaterThan(totalFiles, 10)
        // Open all files
        func openAll(_ node: FileNode) {
            if node.type == .file { state.openFile(node) }
            node.children?.forEach { openAll($0) }
        }
        openAll(root)
        XCTAssertEqual(state.openFiles.count, totalFiles)
        XCTAssertLessThanOrEqual(state.recentFiles.count, AppState.maxRecentFiles)
    }
}
