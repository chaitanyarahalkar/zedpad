import XCTest
@testable import ZedIPad

@MainActor
final class SplitEditorTests: XCTestCase {

    func testSplitInitialState() {
        let state = SplitEditorState()
        XCTAssertFalse(state.isSplit)
        XCTAssertNil(state.secondaryFile)
    }

    func testOpenSplit() {
        let state = SplitEditorState()
        let file = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        state.openSplit(file)
        XCTAssertTrue(state.isSplit)
        XCTAssertEqual(state.secondaryFile?.id, file.id)
    }

    func testCloseSplit() {
        let state = SplitEditorState()
        let file = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        state.openSplit(file)
        state.closeSplit()
        XCTAssertFalse(state.isSplit)
        XCTAssertNil(state.secondaryFile)
    }

    func testOpenSplitReplacesExisting() {
        let state = SplitEditorState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let f2 = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        state.openSplit(f1)
        state.openSplit(f2)
        XCTAssertEqual(state.secondaryFile?.id, f2.id)
        XCTAssertTrue(state.isSplit)
    }

    func testSwapEditors() {
        let state = SplitEditorState()
        var primary: FileNode? = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        var secondary: FileNode? = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let primaryId = primary!.id
        let secondaryId = secondary!.id
        state.swapEditors(primary: &primary, secondary: &secondary)
        XCTAssertEqual(primary?.id, secondaryId)
        XCTAssertEqual(secondary?.id, primaryId)
    }

    func testSwapWithNilPrimary() {
        let state = SplitEditorState()
        var primary: FileNode? = nil
        var secondary: FileNode? = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let secondaryId = secondary!.id
        state.swapEditors(primary: &primary, secondary: &secondary)
        XCTAssertEqual(primary?.id, secondaryId)
        XCTAssertNil(secondary)
    }
}
