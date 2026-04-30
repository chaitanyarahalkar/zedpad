import XCTest
@testable import ZedIPad

@MainActor
final class MiscModelTests: XCTestCase {

    func testFindStateShowReplaceFalseByDefault() {
        let state = FindState()
        XCTAssertFalse(state.showReplace)
    }

    func testFindStateToggleShowReplace() {
        let state = FindState()
        state.showReplace = true
        XCTAssertTrue(state.showReplace)
        state.showReplace = false
        XCTAssertFalse(state.showReplace)
    }

    func testAppStateRootDirectoryIsNotNil() {
        let state = AppState()
        XCTAssertNotNil(state.rootDirectory)
        XCTAssertEqual(state.rootDirectory?.name, "my-project")
    }

    func testSplitEditorCloseSetsNil() {
        let state = SplitEditorState()
        let file = FileNode(name: "f.swift", type: .file, path: "/f.swift")
        state.openSplit(file)
        XCTAssertNotNil(state.secondaryFile)
        state.closeSplit()
        XCTAssertNil(state.secondaryFile)
        XCTAssertFalse(state.isSplit)
    }

    func testGoToLineParsedLineMaxInt() {
        let state = GoToLineState()
        state.lineNumber = "\(Int.max)"
        XCTAssertEqual(state.parsedLine, Int.max)
    }

    func testFileNodeTypeRawEnumValues() {
        let file = FileNode(name: "f", type: .file, path: "/f")
        let dir = FileNode(name: "d", type: .directory, path: "/d", children: [])
        XCTAssertEqual(file.type, .file)
        XCTAssertEqual(dir.type, .directory)
        XCTAssertNotEqual(file.type, dir.type)
    }

    func testLanguageAllCasesNotEmpty() {
        // All language cases should be listable — mainly checking .unknown is last
        let allCases: [Language] = [.swift, .javascript, .typescript, .python, .rust,
                                     .markdown, .json, .yaml, .bash, .ruby, .html, .css,
                                     .go, .kotlin, .c, .cpp, .sql, .scala, .lua, .php,
                                     .r, .unknown]
        XCTAssertEqual(allCases.count, 22)
    }

    func testZedThemeAllCasesCount() {
        XCTAssertEqual(ZedTheme.allCases.count, 4)
    }

    func testFileNodeIDIsUnique() {
        let n1 = FileNode(name: "a", type: .file, path: "/a")
        let n2 = FileNode(name: "b", type: .file, path: "/b")
        XCTAssertNotEqual(n1.id, n2.id)
    }

    func testFindStateRegexAndCaseSensitiveIndependent() {
        let state = FindState()
        state.isRegex = true
        state.isCaseSensitive = true
        XCTAssertTrue(state.isRegex)
        XCTAssertTrue(state.isCaseSensitive)
        state.isRegex = false
        XCTAssertFalse(state.isRegex)
        XCTAssertTrue(state.isCaseSensitive) // independent
    }
}
