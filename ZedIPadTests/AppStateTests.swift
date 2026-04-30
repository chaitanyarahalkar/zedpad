import XCTest
@testable import ZedIPad

@MainActor
final class AppStateTests: XCTestCase {
    func testInitialState() {
        let state = AppState()
        XCTAssertNil(state.activeFile)
        XCTAssertTrue(state.openFiles.isEmpty)
        XCTAssertEqual(state.theme, .dark)
        XCTAssertFalse(state.showingCommandPalette)
        XCTAssertNotNil(state.rootDirectory)
    }

    func testOpenFile() {
        let state = AppState()
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "let x = 1")
        state.openFile(file)
        XCTAssertEqual(state.activeFile?.id, file.id)
        XCTAssertEqual(state.openFiles.count, 1)
    }

    func testOpenFileTwiceDoesNotDuplicate() {
        let state = AppState()
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "")
        state.openFile(file)
        state.openFile(file)
        XCTAssertEqual(state.openFiles.count, 1)
    }

    func testOpenDirectoryDoesNotChangeActiveFile() {
        let state = AppState()
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [])
        state.openFile(dir)
        XCTAssertNil(state.activeFile)
        XCTAssertTrue(state.openFiles.isEmpty)
    }

    func testCloseFile() {
        let state = AppState()
        let file1 = FileNode(name: "a.swift", type: .file, path: "/a.swift", content: "")
        let file2 = FileNode(name: "b.swift", type: .file, path: "/b.swift", content: "")
        state.openFile(file1)
        state.openFile(file2)
        state.closeFile(file1)
        XCTAssertEqual(state.openFiles.count, 1)
        XCTAssertEqual(state.activeFile?.id, file2.id)
    }

    func testCloseLastFileClearsActive() {
        let state = AppState()
        let file = FileNode(name: "only.swift", type: .file, path: "/only.swift", content: "")
        state.openFile(file)
        state.closeFile(file)
        XCTAssertTrue(state.openFiles.isEmpty)
        XCTAssertNil(state.activeFile)
    }

    func testToggleTheme() {
        let state = AppState()
        XCTAssertEqual(state.theme, .dark)
        state.toggleTheme()
        XCTAssertEqual(state.theme, .light)
        state.toggleTheme()
        XCTAssertEqual(state.theme, .dark)
    }
}

@MainActor
final class FileNodeTests: XCTestCase {
    func testDirectoryIcon() {
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [])
        XCTAssertEqual(dir.icon, "folder")
        dir.isExpanded = true
        XCTAssertEqual(dir.icon, "folder.fill")
    }

    func testFileExtensionMapping() {
        let cases: [(String, String)] = [
            ("main.swift", "swift"),
            ("index.js", "j.square"),
            ("app.ts", "j.square"),
            ("main.py", "p.square"),
            ("lib.rs", "r.square"),
            ("data.json", "curlybraces"),
            ("README.md", "doc.text"),
            ("deploy.sh", "terminal"),
            ("index.html", "globe"),
            ("styles.css", "paintbrush"),
            ("Makefile", "doc"),
        ]
        for (name, expectedIcon) in cases {
            let file = FileNode(name: name, type: .file, path: "/\(name)")
            XCTAssertEqual(file.icon, expectedIcon, "Icon mismatch for \(name)")
        }
    }

    func testSampleRootHasExpectedFiles() {
        let root = FileNode.sampleRoot()
        XCTAssertEqual(root.type, .directory)
        XCTAssertTrue(root.isExpanded)
        let names = root.children?.map(\.name) ?? []
        XCTAssertTrue(names.contains("Sources"))
        XCTAssertTrue(names.contains("README.md"))
        XCTAssertTrue(names.contains("Package.swift"))
    }
}
