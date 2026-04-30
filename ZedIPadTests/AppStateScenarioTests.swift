import XCTest
@testable import ZedIPad

@MainActor
final class AppStateScenarioTests: XCTestCase {

    func testOpenEditFindReplace() {
        let state = AppState()
        let file = FileNode(name: "code.py", type: .file, path: "/code.py",
                            content: "print('hello')\nprint('world')")
        state.openFile(file)
        XCTAssertEqual(state.activeFile?.name, "code.py")
        file.content = file.content.replacingOccurrences(of: "print", with: "console.log")
        XCTAssertTrue(file.content.contains("console.log"))
    }

    func testOpenManyFilesAndNavigate() {
        let state = AppState()
        let files = (0..<10).map { i in
            FileNode(name: "file\(i).swift", type: .file, path: "/file\(i).swift",
                     content: "// File \(i)\nlet x = \(i)")
        }
        files.forEach { state.openFile($0) }
        XCTAssertEqual(state.openFiles.count, 10)
        // Navigate back to first file
        state.openFile(files[0])
        XCTAssertEqual(state.activeFile?.id, files[0].id)
        XCTAssertEqual(state.openFiles.count, 10) // no duplicate
    }

    func testSearchResultsUpdate() {
        let find = FindState()
        let content = "The quick brown fox jumps over the lazy dog"
        find.query = "the"
        find.isCaseSensitive = false
        let ranges = find.search(in: content)
        XCTAssertEqual(ranges.count, 2)
        find.isCaseSensitive = true
        let rangesCaseSensitive = find.search(in: content)
        XCTAssertEqual(rangesCaseSensitive.count, 1) // Only "the" (lowercase)
    }

    func testSplitViewThenClose() {
        let appState = AppState()
        let split = SplitEditorState()
        let f1 = FileNode(name: "main.swift", type: .file, path: "/main.swift")
        let f2 = FileNode(name: "view.swift", type: .file, path: "/view.swift")
        appState.openFile(f1)
        appState.openFile(f2)
        split.openSplit(f1)
        XCTAssertTrue(split.isSplit)
        split.closeSplit()
        XCTAssertFalse(split.isSplit)
        XCTAssertEqual(appState.openFiles.count, 2) // unchanged
    }

    func testThemeChangeDoesNotAffectFind() {
        let state = AppState()
        let find = FindState()
        state.theme = .dark
        find.query = "test"
        let ranges1 = find.search(in: "test one two test three test")
        state.theme = .light
        let ranges2 = find.search(in: "test one two test three test")
        XCTAssertEqual(ranges1.count, ranges2.count)
    }

    func testFontSizeDoesNotAffectSearch() {
        let state = AppState()
        let find = FindState()
        state.fontSize = 9
        find.query = "hello"
        let r1 = find.search(in: "hello world hello")
        state.fontSize = 24
        let r2 = find.search(in: "hello world hello")
        XCTAssertEqual(r1.count, r2.count)
    }
}
