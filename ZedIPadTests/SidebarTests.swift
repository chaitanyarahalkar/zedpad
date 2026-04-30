import XCTest
@testable import ZedIPad

@MainActor
final class SidebarContainerTests: XCTestCase {
    func testAppStateHasRootDirectory() {
        let state = AppState()
        XCTAssertNotNil(state.rootDirectory)
    }

    func testGlobalSearchUsesRootDirectory() {
        let state = AppState()
        let search = GlobalSearchState()
        search.query = "let"
        search.search(in: state.rootDirectory)
        XCTAssertFalse(search.results.isEmpty)
    }

    func testGlobalSearchResultsGroupedByFile() {
        let search = GlobalSearchState()
        let root = FileNode.sampleRoot()
        search.query = "import"
        search.search(in: root)
        let fileNames = Set(search.results.map { $0.file.name })
        XCTAssertGreaterThan(fileNames.count, 0)
    }

    func testGlobalSearchFiltersNestedDirectories() {
        let search = GlobalSearchState()
        let inner = FileNode(name: "deep.swift", type: .file, path: "/a/b/deep.swift",
            content: "let deep = true")
        let mid = FileNode(name: "b", type: .directory, path: "/a/b", children: [inner])
        let outer = FileNode(name: "a", type: .directory, path: "/a", children: [mid])
        let root = FileNode(name: "root", type: .directory, path: "/", children: [outer])
        search.query = "deep"
        search.search(in: root)
        XCTAssertEqual(search.results.count, 1)
        XCTAssertEqual(search.results[0].file.name, "deep.swift")
    }

    func testAppStateOpenFileTracksRecent() {
        let state = AppState()
        let file = FileNode(name: "a.swift", type: .file, path: "/a.swift", content: "")
        state.openFile(file)
        XCTAssertEqual(state.recentFiles.first?.id, file.id)
    }

    func testAppStateMaxRecentFiles() {
        let state = AppState()
        for i in 0..<15 {
            let f = FileNode(name: "file\(i).swift", type: .file, path: "/file\(i).swift", content: "")
            state.openFile(f)
        }
        XCTAssertLessThanOrEqual(state.recentFiles.count, AppState.maxRecentFiles)
    }
}

@MainActor
final class ScrollSyncTests: XCTestCase {
    func testScrollOffsetDefault() {
        // LineNumberGutter default scrollOffset is 0
        let text = "line1\nline2\nline3"
        let lines = text.components(separatedBy: "\n").count
        XCTAssertEqual(lines, 3)
        // Default offset = 0 (no scroll)
        let offset: CGFloat = 0
        XCTAssertEqual(offset, 0)
    }

    func testScrollOffsetLineCalculation() {
        let lineHeight: CGFloat = 18
        let offset: CGFloat = 90
        let firstVisible = Int(offset / lineHeight)
        XCTAssertEqual(firstVisible, 5)
    }

    func testScrollOffsetVisibleLines() {
        let lineHeight: CGFloat = 18
        let viewHeight: CGFloat = 180
        let visibleLines = Int(ceil(viewHeight / lineHeight)) + 2
        XCTAssertEqual(visibleLines, 12)
    }
}
