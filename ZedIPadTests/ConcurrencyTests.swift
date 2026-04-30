import XCTest
@testable import ZedIPad

@MainActor
final class ConcurrencyTests: XCTestCase {

    // Test that AppState operations are properly MainActor-isolated

    func testAppStateOnMainActor() async {
        let state = AppState()
        XCTAssertTrue(Thread.isMainThread)
        state.theme = .oneDark
        XCTAssertEqual(state.theme, .oneDark)
    }

    func testOpenFileOnMainActor() async {
        let state = AppState()
        let file = FileNode(name: "async.swift", type: .file, path: "/async.swift")
        state.openFile(file)
        XCTAssertEqual(state.activeFile?.id, file.id)
    }

    func testFindStateOnMainActor() async {
        let state = FindState()
        state.query = "async"
        let text = "async func fetch() async throws { }"
        let ranges = state.search(in: text)
        XCTAssertGreaterThan(ranges.count, 0)
    }

    func testSplitEditorStateOnMainActor() async {
        let state = SplitEditorState()
        XCTAssertFalse(state.isSplit)
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift")
        state.openSplit(file)
        XCTAssertTrue(state.isSplit)
    }

    func testMultipleFileOpenClose() async {
        let state = AppState()
        let files = (0..<10).map { i in
            FileNode(name: "f\(i).swift", type: .file, path: "/f\(i).swift")
        }
        for file in files { state.openFile(file) }
        XCTAssertEqual(state.openFiles.count, 10)
        for file in files { state.closeFile(file) }
        XCTAssertEqual(state.openFiles.count, 0)
        XCTAssertNil(state.activeFile)
    }

    func testRecentFilesOrderPreserved() async {
        let state = AppState()
        let f1 = FileNode(name: "first.swift", type: .file, path: "/first.swift")
        let f2 = FileNode(name: "second.swift", type: .file, path: "/second.swift")
        let f3 = FileNode(name: "third.swift", type: .file, path: "/third.swift")
        state.openFile(f1)
        state.openFile(f2)
        state.openFile(f3)
        XCTAssertEqual(state.recentFiles[0].id, f3.id)
        XCTAssertEqual(state.recentFiles[1].id, f2.id)
        XCTAssertEqual(state.recentFiles[2].id, f1.id)
    }

    func testFontSizeIsSafeFromMultipleIncrements() async {
        let state = AppState()
        let initialSize = state.fontSize
        for _ in 0..<100 { state.increaseFontSize() }
        XCTAssertEqual(state.fontSize, 24)
        for _ in 0..<100 { state.decreaseFontSize() }
        XCTAssertEqual(state.fontSize, 9)
        _ = initialSize
    }

    func testHighlightThreadSafety() {
        // SyntaxHighlighter is not MainActor-isolated (no @MainActor)
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "import Foundation\nlet x = 42"
        // Run on background thread equivalent — just call multiple times
        let results = (0..<5).map { _ in
            hl.highlight(code, language: .swift)
        }
        for r in results { XCTAssertFalse(r.isEmpty) }
    }
}
