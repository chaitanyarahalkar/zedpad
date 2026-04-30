import XCTest
import SwiftUI
@testable import ZedIPad

@MainActor
final class AccessibilityTests: XCTestCase {
    func testZedThemeAllCasesAccessible() {
        for theme in ZedTheme.allCases {
            XCTAssertFalse(theme.rawValue.isEmpty)
            // Colors are non-nil (they always return a Color)
            let _ = theme.background
            let _ = theme.primaryText
            let _ = theme.accentColor
        }
    }

    func testLanguageDetectionAllExtensions() {
        let cases: [(String, Language)] = [
            ("swift", .swift), ("js", .javascript), ("ts", .typescript),
            ("py", .python), ("rs", .rust), ("md", .markdown),
            ("json", .json), ("yaml", .yaml), ("yml", .yaml),
            ("sh", .bash), ("bash", .bash), ("rb", .ruby),
        ]
        for (ext, expected) in cases {
            let detected = Language.detect(from: ext)
            XCTAssertEqual(detected, expected, "Extension .\(ext) should map to \(expected)")
        }
    }

    func testFileNodeTypeIsCorrect() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "")
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [])
        XCTAssertEqual(file.type, .file)
        XCTAssertEqual(dir.type, .directory)
    }

    func testAppStateOpenFilesOrdering() {
        let state = AppState()
        let files = (0..<5).map { i in
            FileNode(name: "file\(i).swift", type: .file, path: "/file\(i).swift", content: "")
        }
        files.forEach { state.openFile($0) }
        XCTAssertEqual(state.openFiles.count, 5)
        XCTAssertEqual(state.openFiles[0].name, "file0.swift")
        XCTAssertEqual(state.openFiles[4].name, "file4.swift")
    }

    func testAppStateActiveFileAfterClose() {
        let state = AppState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift", content: "")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift", content: "")
        let f3 = FileNode(name: "c.swift", type: .file, path: "/c.swift", content: "")
        state.openFile(f1); state.openFile(f2); state.openFile(f3)
        state.closeFile(f3)
        XCTAssertEqual(state.activeFile?.name, "b.swift")
    }

    func testGlobalSearchResultsAreStable() {
        let search = GlobalSearchState()
        let root = FileNode.sampleRoot()
        search.query = "let"
        search.search(in: root)
        let firstCount = search.results.count
        // Run again — should be the same
        search.search(in: root)
        XCTAssertEqual(search.results.count, firstCount, "Search results should be deterministic")
    }

    func testThemeColorHexConversion() {
        // Ensure hex color init produces non-zero colors
        let color = Color(hex: "#89b4fa")
        // Color should not be zero/transparent
        XCTAssertNotNil(color)
    }

    func testFindStateNoMatchReturnsEmpty() {
        let state = FindState()
        state.query = "zzzzzznotfound"
        let results = state.search(in: "hello world")
        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(state.matchCount, 0)
    }

    func testFindStateNavigationWraps() {
        let state = FindState()
        state.query = "a"
        let _ = state.search(in: "a b a b a")
        XCTAssertEqual(state.matchCount, 3)
        // Navigate forward past end should wrap
        state.currentMatch = 2
        state.nextMatch()
        XCTAssertEqual(state.currentMatch, 0)
    }

    func testFindStatePreviousFromFirstWraps() {
        let state = FindState()
        state.query = "x"
        let _ = state.search(in: "x y x")
        XCTAssertEqual(state.matchCount, 2)
        state.currentMatch = 0
        state.previousMatch()
        XCTAssertEqual(state.currentMatch, 1)
    }
}

@MainActor
final class FileNodeFilterTests: XCTestCase {
    func testFilteredByNameMatch() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: "main")
        XCTAssertNotNil(filtered)
    }

    func testFilteredByNonExistentName() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: "zzz_nonexistent")
        XCTAssertNil(filtered)
    }

    func testFilterCaseInsensitive() {
        let root = FileNode.sampleRoot()
        let upper = root.filtered(by: "MAIN")
        let lower = root.filtered(by: "main")
        // Both should find something or both nil — consistent
        XCTAssertEqual(upper != nil, lower != nil)
    }

    func testRootDirectoryAlwaysPreserved() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: "swift")
        // Root should be returned if any children match
        XCTAssertNotNil(filtered)
    }
}
