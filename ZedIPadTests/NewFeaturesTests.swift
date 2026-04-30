import XCTest
@testable import ZedIPad

@MainActor
final class WordWrapTabSizeTests: XCTestCase {
    func testAppStateHasWordWrap() {
        let state = AppState()
        XCTAssertTrue(state.wordWrap)
        state.wordWrap = false
        XCTAssertFalse(state.wordWrap)
    }

    func testAppStateHasTabSize() {
        let state = AppState()
        XCTAssertEqual(state.tabSize, 4)
        state.tabSize = 2
        XCTAssertEqual(state.tabSize, 2)
        state.tabSize = 8
        XCTAssertEqual(state.tabSize, 8)
    }

    func testAppStateHasFindHighlightRanges() {
        let state = AppState()
        XCTAssertTrue(state.findHighlightRanges.isEmpty)
        state.findHighlightRanges = [NSRange(location: 0, length: 5)]
        XCTAssertEqual(state.findHighlightRanges.count, 1)
    }

    func testAppStateHasFindScrollToRange() {
        let state = AppState()
        XCTAssertNil(state.findScrollToRange)
        state.findScrollToRange = NSRange(location: 10, length: 3)
        XCTAssertEqual(state.findScrollToRange?.location, 10)
    }
}

@MainActor
final class FileNodeDirtyTests: XCTestCase {
    func testFileNodeIsDirtyFalseByDefault() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "")
        XCTAssertFalse(file.isDirty)
    }

    func testFileNodeDirtyOnlyWhenHasURL() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "hello")
        file.content = "changed"
        XCTAssertFalse(file.isDirty, "No fileURL → isDirty stays false")
    }

    func testFileNodeDirtyWhenURLSet() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "hello")
        file.fileURL = URL(fileURLWithPath: "/test.swift")
        file.content = "changed"
        XCTAssertTrue(file.isDirty)
    }

    func testFileNodeURLIsNilByDefault() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "")
        XCTAssertNil(file.fileURL)
    }
}

@MainActor
final class GlobalSearchTests: XCTestCase {
    func testSearchFindsMatch() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "import"
        state.search(in: root)
        XCTAssertFalse(state.results.isEmpty)
    }

    func testSearchEmptyQueryClearsResults() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "import"
        state.search(in: root)
        XCTAssertFalse(state.results.isEmpty)
        state.query = ""
        state.search(in: root)
        XCTAssertTrue(state.results.isEmpty)
    }

    func testSearchResultHasLineNumber() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "func"
        state.search(in: root)
        let result = state.results.first
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.lineNumber, 0)
    }

    func testSearchResultHasFileName() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "struct"
        state.search(in: root)
        XCTAssertFalse(state.results.isEmpty)
        XCTAssertFalse(state.results.first!.file.name.isEmpty)
    }

    func testSearchCaseInsensitive() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "IMPORT"
        state.search(in: root)
        XCTAssertFalse(state.results.isEmpty)
    }

    func testSearchNoResultsForNonsense() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "xyzzy_nonexistent_9999"
        state.search(in: root)
        XCTAssertTrue(state.results.isEmpty)
    }

    func testSearchResultLineTextNotEmpty() {
        let state = GlobalSearchState()
        let root = FileNode.sampleRoot()
        state.query = "let"
        state.search(in: root)
        for result in state.results {
            XCTAssertFalse(result.lineText.isEmpty)
        }
    }

    func testSearchOnNilRootReturnsEmpty() {
        let state = GlobalSearchState()
        state.query = "import"
        state.search(in: nil)
        XCTAssertTrue(state.results.isEmpty)
    }
}

@MainActor
final class FindHighlightTests: XCTestCase {
    func testFindStatePublishesMatchRanges() {
        let findState = FindState()
        let text = "hello world hello"
        findState.query = "hello"
        let ranges = findState.search(in: text)
        XCTAssertEqual(ranges.count, 2)
        let nsRanges = ranges.compactMap { NSRange($0, in: text) }
        XCTAssertEqual(nsRanges.count, 2)
        XCTAssertEqual(nsRanges[0].location, 0)
        XCTAssertEqual(nsRanges[1].location, 12)
    }

    func testNSRangeConversionPreservesLength() {
        let findState = FindState()
        let text = "import Foundation"
        findState.query = "import"
        let ranges = findState.search(in: text)
        XCTAssertEqual(ranges.count, 1)
        let nsRange = NSRange(ranges[0], in: text)
        XCTAssertEqual(nsRange.length, 6)
    }
}
