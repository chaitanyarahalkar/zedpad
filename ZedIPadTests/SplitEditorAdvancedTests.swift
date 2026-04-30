import XCTest
@testable import ZedIPad

@MainActor
final class SplitEditorAdvancedTests: XCTestCase {

    func testSplitWithSameFile() {
        let state = SplitEditorState()
        let file = FileNode(name: "same.swift", type: .file, path: "/same.swift")
        state.openSplit(file)
        XCTAssertTrue(state.isSplit)
        XCTAssertEqual(state.secondaryFile?.id, file.id)
    }

    func testSwapNilPrimary() {
        let state = SplitEditorState()
        var primary: FileNode? = nil
        var secondary: FileNode? = FileNode(name: "b", type: .file, path: "/b")
        let secId = secondary!.id
        state.swapEditors(primary: &primary, secondary: &secondary)
        XCTAssertEqual(primary?.id, secId)
        XCTAssertNil(secondary)
    }

    func testSwapNilSecondary() {
        let state = SplitEditorState()
        var primary: FileNode? = FileNode(name: "a", type: .file, path: "/a")
        let primId = primary!.id
        var secondary: FileNode? = nil
        state.swapEditors(primary: &primary, secondary: &secondary)
        XCTAssertNil(primary)
        XCTAssertEqual(secondary?.id, primId)
    }

    func testSwapBothNil() {
        let state = SplitEditorState()
        var primary: FileNode? = nil
        var secondary: FileNode? = nil
        state.swapEditors(primary: &primary, secondary: &secondary)
        XCTAssertNil(primary)
        XCTAssertNil(secondary)
    }

    func testMultipleOpenCloseCycles() {
        let state = SplitEditorState()
        let file = FileNode(name: "cycling.swift", type: .file, path: "/cycling.swift")
        for _ in 0..<10 {
            state.openSplit(file)
            XCTAssertTrue(state.isSplit)
            state.closeSplit()
            XCTAssertFalse(state.isSplit)
        }
    }

    func testSplitStateIndependentFromAppState() {
        let appState = AppState()
        let splitState = SplitEditorState()
        let f1 = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        appState.openFile(f1)
        splitState.openSplit(f1)
        appState.closeFile(f1)
        XCTAssertNil(appState.activeFile)
        XCTAssertTrue(splitState.isSplit) // split state unaffected
    }
}
