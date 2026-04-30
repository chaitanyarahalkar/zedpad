import XCTest
@testable import ZedIPad

@MainActor
final class ModelInvariantTests: XCTestCase {

    // MARK: - AppState invariants

    func testOpenFilesAlwaysContainsActiveFile() {
        let state = AppState()
        let files = (0..<5).map { FileNode(name: "f\($0).swift", type: .file, path: "/f\($0).swift") }
        for f in files {
            state.openFile(f)
            if let active = state.activeFile {
                XCTAssertTrue(state.openFiles.contains { $0.id == active.id },
                              "Active file should always be in openFiles")
            }
        }
    }

    func testActivFileAlwaysNilOrInOpenFiles() {
        let state = AppState()
        let files = (0..<10).map { FileNode(name: "g\($0).swift", type: .file, path: "/g\($0).swift") }
        for f in files { state.openFile(f) }
        for f in files.prefix(5) { state.closeFile(f) }
        if let active = state.activeFile {
            XCTAssertTrue(state.openFiles.contains { $0.id == active.id })
        }
    }

    func testRecentFilesCountNeverExceedsMax() {
        let state = AppState()
        for i in 0..<50 {
            let f = FileNode(name: "r\(i).swift", type: .file, path: "/r\(i).swift")
            state.openFile(f)
            XCTAssertLessThanOrEqual(state.recentFiles.count, AppState.maxRecentFiles)
        }
    }

    // MARK: - FindState invariants

    func testMatchCountAlwaysEqualsRangeCount() {
        let state = FindState()
        let texts = ["", "hello", "hello world hello", "aaa bbb ccc"]
        let queries = ["hello", "a", "b", "xyz"]
        for text in texts {
            for query in queries {
                state.query = query
                let ranges = state.search(in: text)
                XCTAssertEqual(ranges.count, state.matchCount,
                               "matchCount should equal ranges.count")
            }
        }
    }

    func testCurrentMatchAlwaysInRange() {
        let state = FindState()
        state.query = "x"
        let _ = state.search(in: "x y x z x")
        XCTAssertGreaterThanOrEqual(state.currentMatch, 0)
        if state.matchCount > 0 {
            XCTAssertLessThan(state.currentMatch, state.matchCount)
        }
    }

    // MARK: - GoToLineState invariants

    func testGoToLineIsVisibleAlwaysMatchesState() {
        let state = GoToLineState()
        XCTAssertFalse(state.isVisible)
        state.show()
        XCTAssertTrue(state.isVisible)
        state.hide()
        XCTAssertFalse(state.isVisible)
    }

    // MARK: - SplitEditorState invariants

    func testSplitStateConsistency() {
        let state = SplitEditorState()
        // When not split, secondaryFile should be nil
        XCTAssertFalse(state.isSplit)
        XCTAssertNil(state.secondaryFile)
        // When split, secondaryFile should not be nil
        let f = FileNode(name: "f.swift", type: .file, path: "/f.swift")
        state.openSplit(f)
        XCTAssertTrue(state.isSplit)
        XCTAssertNotNil(state.secondaryFile)
        // When closed, secondaryFile should be nil
        state.closeSplit()
        XCTAssertFalse(state.isSplit)
        XCTAssertNil(state.secondaryFile)
    }
}
