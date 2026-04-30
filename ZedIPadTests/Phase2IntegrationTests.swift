import XCTest
@testable import ZedIPad

/// Integration tests covering phase 2 features: word wrap, tab size, global search, file save, find highlight
@MainActor
final class Phase2IntegrationTests: XCTestCase {

    func testWordWrapAndTabSizeIntegration() {
        let state = AppState()
        // Change both settings
        state.wordWrap = false
        state.tabSize = 2
        XCTAssertFalse(state.wordWrap)
        XCTAssertEqual(state.tabSize, 2)
        // Reset via palette commands
        let wrapCmd = PaletteCommand.allCommands.first { $0.title == "Toggle Word Wrap" }
        let tab4Cmd = PaletteCommand.allCommands.first { $0.title == "Tab Size: 4 Spaces" }
        wrapCmd?.action(state)
        tab4Cmd?.action(state)
        XCTAssertTrue(state.wordWrap)
        XCTAssertEqual(state.tabSize, 4)
    }

    func testGlobalSearchAndOpenFileIntegration() {
        let state = AppState()
        let search = GlobalSearchState()
        search.query = "import"
        search.search(in: state.rootDirectory)
        XCTAssertFalse(search.results.isEmpty)
        // Open first result's file
        if let result = search.results.first {
            state.openFile(result.file)
            XCTAssertEqual(state.activeFile?.id, result.file.id)
        }
    }

    func testFindHighlightIntegration() {
        let state = AppState()
        // Simulate find state publishing ranges
        state.findHighlightRanges = [NSRange(location: 0, length: 5), NSRange(location: 10, length: 5)]
        XCTAssertEqual(state.findHighlightRanges.count, 2)
        // Simulate scroll
        state.findScrollToRange = NSRange(location: 10, length: 5)
        XCTAssertEqual(state.findScrollToRange?.location, 10)
        // Clear on dismiss
        state.findHighlightRanges = []
        state.findScrollToRange = nil
        XCTAssertTrue(state.findHighlightRanges.isEmpty)
        XCTAssertNil(state.findScrollToRange)
    }

    func testFileSaveAndDirtyStateIntegration() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("integration_test.swift")
        let file = FileNode(name: "integration_test.swift", type: .file, path: tempURL.path, content: "let x = 1")
        file.fileURL = tempURL
        // Modify content — marks dirty
        file.content = "let x = 42\nlet y = 100"
        XCTAssertTrue(file.isDirty)
        // Save
        try file.content.write(to: tempURL, atomically: true, encoding: .utf8)
        file.isDirty = false
        XCTAssertFalse(file.isDirty)
        // Verify saved content
        let saved = try String(contentsOf: tempURL)
        XCTAssertEqual(saved, "let x = 42\nlet y = 100")
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testThemeAndWordWrapCombination() {
        let state = AppState()
        state.theme = .dark
        state.wordWrap = false
        XCTAssertEqual(state.theme, .dark)
        XCTAssertFalse(state.wordWrap)
        state.toggleTheme()
        XCTAssertEqual(state.theme, .light)
        XCTAssertFalse(state.wordWrap, "Theme toggle should not affect word wrap")
    }

    func testMultipleFilesOpenWithDifferentSettings() {
        let state = AppState()
        let file1 = FileNode(name: "a.swift", type: .file, path: "/a.swift", content: "let a = 1")
        let file2 = FileNode(name: "b.py", type: .file, path: "/b.py", content: "x = 2")
        state.openFile(file1)
        state.openFile(file2)
        XCTAssertEqual(state.openFiles.count, 2)
        // Both files available, settings are global
        state.tabSize = 2
        XCTAssertEqual(state.tabSize, 2)
    }

    func testGlobalSearchDoesNotModifyFiles() {
        let search = GlobalSearchState()
        let root = FileNode.sampleRoot()
        let originalContent = root.children?.first { $0.name == "README.md" }?.content ?? ""
        search.query = "ZedIPad"
        search.search(in: root)
        let afterContent = root.children?.first { $0.name == "README.md" }?.content ?? ""
        XCTAssertEqual(originalContent, afterContent, "Search should not modify file content")
    }

    func testFindStateClearsOnEmptyQuery() {
        let state = AppState()
        state.findHighlightRanges = [NSRange(location: 0, length: 5)]
        state.findScrollToRange = NSRange(location: 0, length: 5)
        // Simulate query cleared
        state.findHighlightRanges = []
        state.findScrollToRange = nil
        XCTAssertTrue(state.findHighlightRanges.isEmpty)
        XCTAssertNil(state.findScrollToRange)
    }

    func testCommandPaletteActionsOnRealState() {
        let state = AppState()
        // Apply all theme commands and verify state changes
        let themes: [(String, ZedTheme)] = [
            ("Dark Theme", .dark), ("Light Theme", .light),
            ("One Dark Theme", .oneDark), ("Solarized Dark Theme", .solarizedDark)
        ]
        for (title, expected) in themes {
            if let cmd = PaletteCommand.allCommands.first(where: { $0.title == title }) {
                cmd.action(state)
                XCTAssertEqual(state.theme, expected, "\(title) should set theme to \(expected)")
            }
        }
    }
}
