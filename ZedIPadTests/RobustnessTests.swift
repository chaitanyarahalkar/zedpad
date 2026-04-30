import XCTest
@testable import ZedIPad

@MainActor
final class RobustnessTests: XCTestCase {

    func testHighlightDoesNotCrashOnNull() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let x: String? = nil\nif let s = x { print(s) }"
        _ = hl.highlight(code, language: .swift)
    }

    func testFindWithEmptyReplace() {
        let find = FindState()
        find.query = "delete_me"
        find.replaceQuery = ""
        var text = "keep delete_me keep delete_me keep"
        let count = find.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertFalse(text.contains("delete_me"))
        XCTAssertTrue(text.contains("keep"))
    }

    func testAppStateWithManyThemeChanges() {
        let state = AppState()
        for _ in 0..<100 { state.toggleTheme() }
        // After 100 toggles (even), should be back to dark
        XCTAssertEqual(state.theme, .dark)
    }

    func testFileNodeWithVeryLongContent() {
        let longContent = String(repeating: "let x = 42\n", count: 1000)
        let file = FileNode(name: "long.swift", type: .file, path: "/long.swift", content: longContent)
        XCTAssertEqual(file.content.components(separatedBy: "\n").count - 1, 1000)
    }

    func testHighlightDoesNotMutateInput() {
        let hl = SyntaxHighlighter(theme: .dark)
        let original = "import Foundation\nlet x = 1"
        let copy = original
        _ = hl.highlight(original, language: .swift)
        XCTAssertEqual(original, copy)
    }

    func testFindStateSearchDoesNotMutate() {
        let find = FindState()
        find.query = "test"
        let original = "test one test two test three"
        let copy = original
        _ = find.search(in: original)
        XCTAssertEqual(original, copy)
    }

    func testGoToLineWithExtremeValues() {
        let state = GoToLineState()
        let extremes = ["1", "999999", "0", "-1", "9999999999999999"]
        for val in extremes {
            state.lineNumber = val
            _ = state.parsedLine // no crash
        }
    }

    func testAppStateWithNilRootDirectory() {
        let state = AppState()
        state.rootDirectory = nil
        // Should not crash when accessing nil root
        XCTAssertNil(state.rootDirectory)
        // Operations should be safe
        let file = FileNode(name: "f.swift", type: .file, path: "/f.swift")
        state.openFile(file)
        XCTAssertEqual(state.activeFile?.id, file.id)
    }
}
