import XCTest
@testable import ZedIPad

@MainActor
final class AppStatePersistenceTests: XCTestCase {

    func testOpenFilePersistsInOpenFiles() {
        let state = AppState()
        let files = (0..<5).map { FileNode(name: "f\($0).swift", type: .file, path: "/f\($0).swift") }
        files.forEach { state.openFile($0) }
        XCTAssertEqual(state.openFiles.count, 5)
        XCTAssertEqual(state.openFiles.map(\.name), ["f0.swift","f1.swift","f2.swift","f3.swift","f4.swift"])
    }

    func testActiveFileAfterMultipleOpens() {
        let state = AppState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        state.openFile(f1)
        XCTAssertEqual(state.activeFile?.id, f1.id)
        state.openFile(f2)
        XCTAssertEqual(state.activeFile?.id, f2.id)
    }

    func testThemePersistsAfterFileOperations() {
        let state = AppState()
        state.theme = .solarizedDark
        let file = FileNode(name: "x.swift", type: .file, path: "/x.swift")
        state.openFile(file)
        state.closeFile(file)
        XCTAssertEqual(state.theme, .solarizedDark) // theme unchanged
    }

    func testFontSizePersistsAfterFileOperations() {
        let state = AppState()
        state.increaseFontSize()
        state.increaseFontSize()
        let expected = state.fontSize
        let file = FileNode(name: "y.swift", type: .file, path: "/y.swift")
        state.openFile(file)
        state.closeFile(file)
        XCTAssertEqual(state.fontSize, expected)
    }

    func testRecentFilesOrderAfterMultipleOperations() {
        let state = AppState()
        let files = (0..<5).map { FileNode(name: "r\($0).swift", type: .file, path: "/r\($0).swift") }
        for f in files { state.openFile(f) }
        // Most recent is last opened
        XCTAssertEqual(state.recentFiles[0].id, files[4].id)
        // Re-open first file — it should move to front
        state.openFile(files[0])
        XCTAssertEqual(state.recentFiles[0].id, files[0].id)
        XCTAssertEqual(state.recentFiles[1].id, files[4].id)
    }

    func testCommandPaletteDefaultClosed() {
        let state = AppState()
        XCTAssertFalse(state.showingCommandPalette)
    }

    func testOpenFilesListOrdering() {
        let state = AppState()
        let a = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let b = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let c = FileNode(name: "c.swift", type: .file, path: "/c.swift")
        state.openFile(a); state.openFile(b); state.openFile(c)
        XCTAssertEqual(state.openFiles[0].id, a.id)
        XCTAssertEqual(state.openFiles[1].id, b.id)
        XCTAssertEqual(state.openFiles[2].id, c.id)
    }

    func testCloseMiddleFile() {
        let state = AppState()
        let a = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let b = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let c = FileNode(name: "c.swift", type: .file, path: "/c.swift")
        state.openFile(a); state.openFile(b); state.openFile(c)
        state.closeFile(b)
        XCTAssertEqual(state.openFiles.count, 2)
        XCTAssertEqual(state.openFiles[0].id, a.id)
        XCTAssertEqual(state.openFiles[1].id, c.id)
        XCTAssertEqual(state.activeFile?.id, c.id) // active was c, unchanged
    }

    func testMaxFontSizeBoundary() {
        let state = AppState()
        state.fontSize = 24
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, 24) // capped
        state.fontSize = 9
        state.decreaseFontSize()
        XCTAssertEqual(state.fontSize, 9) // floored
    }
}
