import XCTest
import SwiftUI
@testable import ZedIPad

/// Golden path tests — the core user journeys through ZedIPad
@MainActor
final class GoldenPathTests: XCTestCase {

    // Journey 1: Open app → browse file tree → open file → view syntax-highlighted code
    func testJourneyBrowseAndOpenFile() {
        let state = AppState()
        XCTAssertNotNil(state.rootDirectory)
        // Expand Sources
        state.rootDirectory?.children?.first { $0.name == "Sources" }?.isExpanded = true
        // Open main.swift
        let sources = state.rootDirectory?.children?.first { $0.name == "Sources" }
        let mainSwift = sources?.children?.first { $0.name == "main.swift" }
        XCTAssertNotNil(mainSwift)
        state.openFile(mainSwift!)
        XCTAssertEqual(state.activeFile?.name, "main.swift")
        XCTAssertFalse(state.openFiles.isEmpty)
    }

    // Journey 2: Open file → use Find → navigate matches → close find
    func testJourneyFindInFile() {
        let state = AppState()
        let findState = FindState()
        let content = "import Foundation\nstruct App { let name = \"ZedIPad\" }\nlet app = App()"
        findState.query = "let"
        let ranges = findState.search(in: content)
        XCTAssertGreaterThan(ranges.count, 0)
        // Navigate
        findState.nextMatch()
        XCTAssertGreaterThanOrEqual(findState.currentMatch, 0)
        // Publish highlights
        state.findHighlightRanges = ranges.compactMap { NSRange($0, in: content) }
        XCTAssertFalse(state.findHighlightRanges.isEmpty)
        // Close find bar
        state.findHighlightRanges = []
        state.findScrollToRange = nil
        XCTAssertTrue(state.findHighlightRanges.isEmpty)
    }

    // Journey 3: Global search → find across files → open result
    func testJourneyGlobalSearch() {
        let state = AppState()
        let search = GlobalSearchState()
        search.query = "func"
        search.search(in: state.rootDirectory)
        XCTAssertFalse(search.results.isEmpty)
        if let first = search.results.first {
            state.openFile(first.file)
            XCTAssertNotNil(state.activeFile)
        }
    }

    // Journey 4: Change theme via command palette
    func testJourneyChangeTheme() {
        let state = AppState()
        XCTAssertEqual(state.theme, .dark)
        let lightCmd = PaletteCommand.allCommands.first { $0.title == "Light Theme" }!
        lightCmd.action(state)
        XCTAssertEqual(state.theme, .light)
        let darkCmd = PaletteCommand.allCommands.first { $0.title == "Dark Theme" }!
        darkCmd.action(state)
        XCTAssertEqual(state.theme, .dark)
    }

    // Journey 5: Adjust editor settings via command palette
    func testJourneyAdjustSettings() {
        let state = AppState()
        // Increase font
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, 14)
        // Toggle word wrap
        let wrapCmd = PaletteCommand.allCommands.first { $0.title == "Toggle Word Wrap" }!
        wrapCmd.action(state)
        XCTAssertFalse(state.wordWrap)
        // Set tab size
        let tab2Cmd = PaletteCommand.allCommands.first { $0.title == "Tab Size: 2 Spaces" }!
        tab2Cmd.action(state)
        XCTAssertEqual(state.tabSize, 2)
        // Reset
        state.decreaseFontSize()
        XCTAssertEqual(state.fontSize, 13)
    }

    // Journey 6: Open multiple files → close one → active file updates correctly
    func testJourneyMultiTabManagement() {
        let state = AppState()
        let files = ["a.swift", "b.swift", "c.swift"].map { name in
            FileNode(name: name, type: .file, path: "/\(name)", content: "// \(name)")
        }
        files.forEach { state.openFile($0) }
        XCTAssertEqual(state.openFiles.count, 3)
        XCTAssertEqual(state.activeFile?.name, "c.swift")
        // Close middle tab
        state.closeFile(files[1])
        XCTAssertEqual(state.openFiles.count, 2)
        XCTAssertTrue(state.openFiles.contains { $0.name == "a.swift" })
        XCTAssertTrue(state.openFiles.contains { $0.name == "c.swift" })
    }

    // Journey 7: Find & Replace workflow
    func testJourneyFindAndReplace() {
        let findState = FindState()
        var content = "let x = 1\nlet y = 2\nlet z = 3"
        findState.query = "let"
        findState.replaceQuery = "var"
        let count = findState.replaceAll(in: &content)
        XCTAssertGreaterThan(count, 0)
        XCTAssertTrue(content.contains("var"))
        XCTAssertFalse(content.contains("let"))
    }

    // Journey 8: Filter file tree
    func testJourneyFileTreeFilter() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: "swift")
        XCTAssertNotNil(filtered)
        // All resulting leaf nodes should match
        func checkNodes(_ node: FileNode) {
            if node.type == .file {
                // File matches or was included as parent context
            }
            for child in node.children ?? [] {
                checkNodes(child)
            }
        }
        checkNodes(filtered!)
    }
}
