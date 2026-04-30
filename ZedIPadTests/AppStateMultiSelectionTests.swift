import XCTest
@testable import ZedIPad

@MainActor
final class AppStateMultiSelectionTests: XCTestCase {

    func testSelectAndDeselectFiles() {
        let state = AppState()
        let files = (0..<5).map { FileNode(name: "s\($0).swift", type: .file, path: "/s\($0).swift") }
        files.forEach { state.openFile($0) }
        // Open files selectively
        state.openFile(files[0])
        XCTAssertEqual(state.activeFile?.id, files[0].id)
        state.openFile(files[3])
        XCTAssertEqual(state.activeFile?.id, files[3].id)
        state.openFile(files[1])
        XCTAssertEqual(state.activeFile?.id, files[1].id)
        XCTAssertEqual(state.openFiles.count, 5)
    }

    func testCloseAllFilesAndReopen() {
        let state = AppState()
        let files = (0..<3).map { FileNode(name: "r\($0).swift", type: .file, path: "/r\($0).swift") }
        files.forEach { state.openFile($0) }
        files.forEach { state.closeFile($0) }
        XCTAssertTrue(state.openFiles.isEmpty)
        // Reopen
        files.forEach { state.openFile($0) }
        XCTAssertEqual(state.openFiles.count, 3)
    }

    func testActiveFileAfterOpenAndClose() {
        let state = AppState()
        let a = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let b = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        state.openFile(a); state.openFile(b)
        XCTAssertEqual(state.activeFile?.id, b.id)
        state.closeFile(b)
        XCTAssertEqual(state.activeFile?.id, a.id) // falls back to a
        state.closeFile(a)
        XCTAssertNil(state.activeFile)
    }

    func testFontSizeIncrDecr() {
        let state = AppState()
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, 14)
        state.decreaseFontSize()
        XCTAssertEqual(state.fontSize, 13)
        state.decreaseFontSize()
        XCTAssertEqual(state.fontSize, 12)
        state.increaseFontSize()
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, 14)
    }

    func testThemeDefaultIsZedDark() {
        let state = AppState()
        XCTAssertEqual(state.theme, .dark)
        XCTAssertEqual(state.theme.rawValue, "Zed Dark")
    }

    func testShowingCommandPaletteDefault() {
        let state = AppState()
        XCTAssertFalse(state.showingCommandPalette)
        state.showingCommandPalette = true
        XCTAssertTrue(state.showingCommandPalette)
    }
}
