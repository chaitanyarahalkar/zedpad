import XCTest
@testable import ZedIPad

@MainActor
final class AppStateFileManagementTests: XCTestCase {

    func testOpenAndCloseFileCycle() {
        let state = AppState()
        for _ in 0..<5 {
            let f = FileNode(name: UUID().uuidString + ".swift", type: .file, path: "/tmp/f.swift")
            state.openFile(f)
            XCTAssertEqual(state.activeFile?.id, f.id)
            state.closeFile(f)
            XCTAssertNil(state.activeFile)
        }
    }

    func testSwitchActiveFileWithManyOpen() {
        let state = AppState()
        let files = (0..<20).map { FileNode(name: "x\($0).swift", type: .file, path: "/x\($0).swift") }
        files.forEach { state.openFile($0) }
        for file in files {
            state.openFile(file)
            XCTAssertEqual(state.activeFile?.id, file.id)
        }
        XCTAssertEqual(state.openFiles.count, 20)
    }

    func testCloseAllFilesOneByOne() {
        let state = AppState()
        let files = (0..<5).map { FileNode(name: "c\($0).swift", type: .file, path: "/c\($0).swift") }
        files.forEach { state.openFile($0) }
        for file in files.reversed() {
            state.closeFile(file)
        }
        XCTAssertTrue(state.openFiles.isEmpty)
        XCTAssertNil(state.activeFile)
    }

    func testOpenDirectoriesNotAddedToOpenFiles() {
        let state = AppState()
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [])
        state.openFile(dir)
        XCTAssertTrue(state.openFiles.isEmpty)
        XCTAssertNil(state.activeFile)
    }

    func testCloseNonExistentFileNoCrash() {
        let state = AppState()
        let phantom = FileNode(name: "ghost.swift", type: .file, path: "/ghost.swift")
        state.closeFile(phantom) // should not crash
        XCTAssertTrue(state.openFiles.isEmpty)
    }

    func testActiveFileChangesOnClose() {
        let state = AppState()
        let a = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let b = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let c = FileNode(name: "c.swift", type: .file, path: "/c.swift")
        state.openFile(a); state.openFile(b); state.openFile(c)
        XCTAssertEqual(state.activeFile?.id, c.id)
        state.closeFile(c) // close active → should become last remaining
        XCTAssertEqual(state.activeFile?.id, b.id)
    }
}
