import XCTest
@testable import ZedIPad

@MainActor
final class AppStateExtendedTests: XCTestCase {

    // MARK: - Recent files

    func testRecentFilesTracked() {
        let state = AppState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        state.openFile(f1)
        state.openFile(f2)
        XCTAssertEqual(state.recentFiles.count, 2)
        XCTAssertEqual(state.recentFiles[0].id, f2.id) // most recent first
        XCTAssertEqual(state.recentFiles[1].id, f1.id)
    }

    func testRecentFilesDeduplicates() {
        let state = AppState()
        let f = FileNode(name: "x.swift", type: .file, path: "/x.swift")
        state.openFile(f)
        state.openFile(f)
        state.openFile(f)
        XCTAssertEqual(state.recentFiles.count, 1)
    }

    func testRecentFilesCappedAtMax() {
        let state = AppState()
        for i in 0..<15 {
            let f = FileNode(name: "f\(i).swift", type: .file, path: "/f\(i).swift")
            state.openFile(f)
        }
        XCTAssertLessThanOrEqual(state.recentFiles.count, AppState.maxRecentFiles)
    }

    func testRecentFilesMovedToFront() {
        let state = AppState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let f3 = FileNode(name: "c.swift", type: .file, path: "/c.swift")
        state.openFile(f1)
        state.openFile(f2)
        state.openFile(f3)
        state.openFile(f1) // revisit f1 — should move to front
        XCTAssertEqual(state.recentFiles[0].id, f1.id)
    }

    // MARK: - Font size

    func testDefaultFontSize() {
        let state = AppState()
        XCTAssertEqual(state.fontSize, 13)
    }

    func testIncreaseFontSize() {
        let state = AppState()
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, 14)
    }

    func testDecreaseFontSize() {
        let state = AppState()
        state.decreaseFontSize()
        XCTAssertEqual(state.fontSize, 12)
    }

    func testFontSizeUpperBound() {
        let state = AppState()
        for _ in 0..<20 { state.increaseFontSize() }
        XCTAssertEqual(state.fontSize, 24)
    }

    func testFontSizeLowerBound() {
        let state = AppState()
        for _ in 0..<20 { state.decreaseFontSize() }
        XCTAssertEqual(state.fontSize, 9)
    }

    // MARK: - Command palette

    func testCommandPaletteToggle() {
        let state = AppState()
        XCTAssertFalse(state.showingCommandPalette)
        state.showingCommandPalette = true
        XCTAssertTrue(state.showingCommandPalette)
        state.showingCommandPalette = false
        XCTAssertFalse(state.showingCommandPalette)
    }

    // MARK: - Theme cycling

    func testAllThemesToggle() {
        let state = AppState()
        let initial = state.theme
        state.toggleTheme()
        XCTAssertNotEqual(state.theme, initial)
        state.toggleTheme()
        XCTAssertEqual(state.theme, initial)
    }

    // MARK: - Multi-file management

    func testOpenMultipleFilesAndSwitchActive() {
        let state = AppState()
        let files = (0..<5).map { i in
            FileNode(name: "file\(i).swift", type: .file, path: "/file\(i).swift")
        }
        files.forEach { state.openFile($0) }
        XCTAssertEqual(state.openFiles.count, 5)
        XCTAssertEqual(state.activeFile?.id, files.last?.id)
        // Switch to first
        state.openFile(files[0])
        XCTAssertEqual(state.activeFile?.id, files[0].id)
        XCTAssertEqual(state.openFiles.count, 5) // no duplicate
    }

    func testCloseNonActiveFile() {
        let state = AppState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let f3 = FileNode(name: "c.swift", type: .file, path: "/c.swift")
        state.openFile(f1)
        state.openFile(f2)
        state.openFile(f3)
        state.closeFile(f1) // close non-active
        XCTAssertEqual(state.openFiles.count, 2)
        XCTAssertEqual(state.activeFile?.id, f3.id) // active unchanged
    }
}
