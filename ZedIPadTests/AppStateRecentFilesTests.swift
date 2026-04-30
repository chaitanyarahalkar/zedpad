import XCTest
@testable import ZedIPad

@MainActor
final class AppStateRecentFilesTests: XCTestCase {

    func testRecentFilesEmptyOnInit() {
        let state = AppState()
        XCTAssertTrue(state.recentFiles.isEmpty)
    }

    func testSingleFileInRecent() {
        let state = AppState()
        let file = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        state.openFile(file)
        XCTAssertEqual(state.recentFiles.count, 1)
        XCTAssertEqual(state.recentFiles.first?.id, file.id)
    }

    func testRecentFilesMaxLimitExact() {
        let state = AppState()
        for i in 0..<AppState.maxRecentFiles {
            let f = FileNode(name: "f\(i).swift", type: .file, path: "/f\(i).swift")
            state.openFile(f)
        }
        XCTAssertEqual(state.recentFiles.count, AppState.maxRecentFiles)
    }

    func testRecentFilesExceedsMax() {
        let state = AppState()
        for i in 0..<(AppState.maxRecentFiles + 5) {
            let f = FileNode(name: "f\(i).swift", type: .file, path: "/f\(i).swift")
            state.openFile(f)
        }
        XCTAssertEqual(state.recentFiles.count, AppState.maxRecentFiles)
    }

    func testMostRecentIsFirst() {
        let state = AppState()
        let files = (0..<5).map { FileNode(name: "f\($0).swift", type: .file, path: "/f\($0).swift") }
        for f in files { state.openFile(f) }
        XCTAssertEqual(state.recentFiles.first?.id, files.last?.id)
    }

    func testRecentFilesAfterClose() {
        let state = AppState()
        let file = FileNode(name: "c.swift", type: .file, path: "/c.swift")
        state.openFile(file)
        state.closeFile(file)
        // Recent files should still contain the file
        XCTAssertEqual(state.recentFiles.count, 1)
        XCTAssertEqual(state.recentFiles.first?.id, file.id)
    }

    func testRecentFilesNoDuplicates() {
        let state = AppState()
        let file = FileNode(name: "dup.swift", type: .file, path: "/dup.swift")
        for _ in 0..<5 { state.openFile(file) }
        XCTAssertEqual(state.recentFiles.count, 1)
    }

    func testRecentFilesOrderAfterReopen() {
        let state = AppState()
        let a = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let b = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let c = FileNode(name: "c.swift", type: .file, path: "/c.swift")
        state.openFile(a); state.openFile(b); state.openFile(c)
        // c is most recent
        XCTAssertEqual(state.recentFiles[0].id, c.id)
        // Now reopen a
        state.openFile(a)
        // a should now be most recent
        XCTAssertEqual(state.recentFiles[0].id, a.id)
        XCTAssertEqual(state.recentFiles[1].id, c.id)
        XCTAssertEqual(state.recentFiles[2].id, b.id)
    }
}
