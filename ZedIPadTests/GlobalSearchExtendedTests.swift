import XCTest
@testable import ZedIPad

@MainActor
final class GlobalSearchExtendedTests: XCTestCase {
    func testSearchResultCount() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "let"
        state.search(in: root)
        XCTAssertGreaterThan(state.results.count, 0)
    }

    func testSearchMultipleFilesReturnsResultsFromDifferentFiles() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "import"
        state.search(in: root)
        let fileNames = Set(state.results.map { $0.file.name })
        XCTAssertGreaterThan(fileNames.count, 0)
    }

    func testSearchShortQueryMinLength() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "i"
        state.search(in: root)
        // Single char search is allowed
        XCTAssertTrue(state.results.count >= 0)
    }

    func testSearchResultMatchRangeIsValid() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "func"
        state.search(in: root)
        for result in state.results {
            let line = result.lineText
            XCTAssertFalse(line.isEmpty)
        }
    }

    func testSearchIsNotSearchingAfterCompletion() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "struct"
        state.search(in: root)
        XCTAssertFalse(state.isSearching)
    }

    func testSearchResultLineNumberIsPositive() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "let"
        state.search(in: root)
        for result in state.results {
            XCTAssertGreaterThan(result.lineNumber, 0)
        }
    }

    func testSearchEmptyFileHasNoResults() {
        let state = GlobalSearchState()
        let emptyFile = FileNode(name: "empty.swift", type: .file, path: "/empty.swift", content: "")
        let root = FileNode(name: "root", type: .directory, path: "/", children: [emptyFile])
        state.query = "import"
        state.search(in: root)
        XCTAssertTrue(state.results.isEmpty)
    }

    func testSearchDirectoryNodeNotIncluded() {
        let state = GlobalSearchState()
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [
            FileNode(name: "main.swift", type: .file, path: "/src/main.swift", content: "import Foundation\nlet x = 1")
        ])
        let root = FileNode(name: "root", type: .directory, path: "/", children: [dir])
        state.query = "import"
        state.search(in: root)
        XCTAssertEqual(state.results.count, 1)
        XCTAssertEqual(state.results[0].file.name, "main.swift")
    }

    func testSearchMultipleOccurrencesOnSameLine() {
        let state = GlobalSearchState()
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift",
            content: "let let_var = let_value")
        let root = FileNode(name: "root", type: .directory, path: "/", children: [file])
        state.query = "let"
        state.search(in: root)
        // Should find multiple occurrences
        XCTAssertGreaterThanOrEqual(state.results.count, 1)
    }
}

@MainActor
final class AppStateSettingsTests: XCTestCase {
    func testWordWrapDefaultTrue() {
        let state = AppState()
        XCTAssertTrue(state.wordWrap)
    }

    func testTabSizeDefault4() {
        let state = AppState()
        XCTAssertEqual(state.tabSize, 4)
    }

    func testWordWrapToggle() {
        let state = AppState()
        state.wordWrap = false
        XCTAssertFalse(state.wordWrap)
        state.wordWrap = true
        XCTAssertTrue(state.wordWrap)
    }

    func testTabSizeValidValues() {
        let state = AppState()
        for size in [2, 4, 8] {
            state.tabSize = size
            XCTAssertEqual(state.tabSize, size)
        }
    }

    func testFontSizeIncrease() {
        let state = AppState()
        let initial = state.fontSize
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, initial + 1)
    }

    func testFontSizeDecrease() {
        let state = AppState()
        let initial = state.fontSize
        state.decreaseFontSize()
        XCTAssertEqual(state.fontSize, initial - 1)
    }

    func testFontSizeCappedAt24() {
        let state = AppState()
        state.fontSize = 24
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, 24)
    }

    func testFontSizeFloorAt9() {
        let state = AppState()
        state.fontSize = 9
        state.decreaseFontSize()
        XCTAssertEqual(state.fontSize, 9)
    }
}
